require "http/request"
require "./timeable"

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
      EventSystem::Global.publish(self.class, "exception", ExceptionEvent.new(e, context))
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

    getter :router

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

      def initialize(@original : C)
      end
    end

    getter :headers, :successor

    def initialize(@headers : Hash(String, String), @successor)
    end

    def call(context : C) : HTTP::Response
      response = successor.call(Context.new(context))
      response.headers.merge!(headers)
      response
    end
  end

  module MiddlewareBuilder
    macro define_middleware_stack(hash)
      {% classes = hash.to_a %}
      {% for c, idx in classes %}
        {% if idx == 0 %}
          {{c[0]}}(Tjeneste::HttpContext).new(
        {% elsif idx == classes.size - 1 %}
          {{c[0]}}({{classes[idx-1][0]}}::Context).new(*{{c[1]}}
        {% else %}
          {{c[0]}}({{classes[idx-1][0]}}::Context).new(
        {% end %}
      {% end %}
      {% for c, idx in classes %}
      )
      {% end %}
    end
  end

end


# module Tjeneste
#   abstract class Middleware
#     getter :successor

#     def initialize(@successor = nil)
#     end

#     def call(req : HTTP::Request) : HTTP::Response
#       case s = successor
#       when Middleware then s.call(req)
#       when Proc(HTTP::Request, HTTP::Response) then s.call(req)
#       when Nil then HTTP::Response.not_found
#       else raise ArgumentError.new("Invalid middleware: #{s.inspect}")
#       end
#     end
#   end

#   class TimingMiddleware < Middleware
#     include Timeable

#     class RequestTimingEvent < EventSystem::Event
#       @request :: HTTP::Request
#       @response :: HTTP::Response
#       @timing :: Timeable::Timing

#       getter :request, :response, :timing

#       def initialize(@timing, @request, @response)
#       end
#     end

#     def call(req : HTTP::Request) : HTTP::Response
#       response, timing = profile do
#         super
#       end

#       EventSystem::Global.publish(self.class, "timing", RequestTimingEvent.new(timing, req, response))

#       response
#     end
#   end

#   class ExceptionMiddleware < Middleware

#     class ExceptionEvent < EventSystem::Event
#       getter :exception

#       def initialize(@exception, @request : HTTP::Request)
#       end
#     end

#     def call(request : HTTP::Request)
#       super
#     rescue e
#       EventSystem::Global.publish(self.class, "exception", ExceptionEvent.new(e, request))
#       HTTP::Response.new(500, "Internal Server Error")
#     end
#   end

#   class RoutingMiddleware < Middleware
#     getter :router

#     def initialize(@router : Routing::Router)
#     end

#     def call(req : HTTP::Request) : HTTP::Response
#       route = router.route!(req)

#       route.action.call(req)
#     rescue Routing::Router::NoRouteFoundException
#       HTTP::Response.not_found
#     end
#   end

#   class HeaderMiddleware < Middleware
#     getter :headers

#     def initialize(@headers = {} of String => String, @successor = nil)
#     end

#     def call(req : HTTP::Request)
#       response = super
#       response.headers.merge!(headers)
#       response
#     end
#   end

# end
