require "http/request"
require "./timeable"
require "secure_random"

module Tjeneste
  abstract class Middleware
    abstract def successor
  end

  class TimingMiddleware(C) < Middleware
    include Timeable

    class RequestTimingEvent < EventSystem::Event
      getter context, timing, response

      def initialize(@timing, @context : C, @response)
      end
    end

    class Context # FIXME Context = C
      forward_missing_to original

      getter original

      def initialize(@original : C)
      end
    end

    getter successor

    def initialize(@successor)
    end

    def call(context : C)
      result, timing = profile do
        successor.call(Context.new(context))
      end

      EventSystem::Global.publish(TimingMiddleware, "timing", RequestTimingEvent.new(timing, context, result))
      result
    end
  end

  class ExceptionMiddleware(C) < Middleware

    class ExceptionEvent < EventSystem::Event
      getter :exception

      def initialize(@exception, @context : C)
      end
    end

    class Context # FIXME Context = C
      forward_missing_to original

      getter original

      def initialize(@original : C)
      end
    end

    def initialize(@successor)
    end

    getter successor

    def call(context : C) : HTTP::Response
      successor.call(Context.new(context))
    rescue e
      EventSystem::Global.publish(ExceptionMiddleware, "exception", ExceptionEvent.new(e, context))
      HTTP::Response.new(500, "Internal Server Error")
    end
  end

  class RoutingEndpoint(C)

    class Context # FIXME Context = C
      forward_missing_to original

      getter original

      def initialize(@original : C)
      end
    end

    getter router

    def initialize(@router : Routing::Router)
    end

    def call(context : C)
      route = router.route(context.request)

      if route
        route.action.call(context.request)
      else
        HTTP::Response.not_found
      end
    end
  end

  class HeaderMiddleware(C) < Middleware

    class Context # FIXME Context = C
      forward_missing_to original
      getter original

      def initialize(@original : C)
      end
    end

    getter headers, successor

    def initialize(@headers : Hash(String, String), @successor)
    end

    def call(context : C) : HTTP::Response
      response = successor.call(Context.new(context))
      response.headers.merge!(headers)
      response
    end
  end

  class SessionMiddleware(C) < Middleware
    class Context
      forward_missing_to original
      getter original

      def initialize(@original : C, @session_id_name : String)
      end

      def session_id
        original.request.cookies[@session_id_name]?
      end
    end

    getter successor

    def initialize(@session_id_name : String, @successor)
    end

    def call(context : C) : HTTP::Response
      ctx = Context.new(context, @session_id_name)
      response = successor.call(ctx)

      if !ctx.session_id
        response.cookies << HTTP::Cookie.new(
          @session_id_name,
          generate_session_id,
          path: "/",
          expires: 1.day.from_now,
          http_only: true
        )
      end

      response
    end

    private def generate_session_id
      SecureRandom.hex
    end
  end

  module MiddlewareBuilder
    macro define_middleware_stack(hash)
      {% classes = hash.to_a %}
      nested_middleware_stack({{classes}}, 0)
    end

    macro nested_middleware_stack(array, i)
      {% cls = array[i][0] %}
      {% params = array[i][1] %}
      {% if i == 0 %}
        {% ctx = Tjeneste::HttpContext %}
      {% else %}
        {% ctx = array[i-1][0].id + "::Context" %}
      {% end %}

      {% if i == array.size - 1 %}
        {{cls}}({{ctx}}).new(*{{params}})
      {% else %}
        {{cls}}({{ctx}}).new(*{{params}}, nested_middleware_stack({{array}}, {{i+1}}))
      {% end %}
    end

  end

end
