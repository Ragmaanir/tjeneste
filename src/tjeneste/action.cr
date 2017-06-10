require "json"

require "./action/validation"

module Tjeneste
  module Action
    abstract class AbstractLazyAction
      # FIXME crystal bug: does not recognize abstract def
      # abstract def call(ctx : HTTP::Server::Context, route : Tjeneste::Routing::Route)
      def call(ctx : HTTP::Server::Context, route : Tjeneste::Routing::Route)
        raise "err"
      end
    end

    class LazyAction(App, Ctx) < AbstractLazyAction
      getter app : App
      getter action_factory : (App) -> Action::AbstractAction

      def initialize(@app, &@action_factory : (App) -> Action::AbstractAction)
      end

      def call(ctx : HTTP::Server::Context, route : Tjeneste::Routing::Route)
        @action_factory.call(app).call_wrapper(ctx, route)
      end
    end

    module AbstractAction
    end

    module Base(App, Ctx)
      include AbstractAction

      module MIME
        HTML = "text/html; charset=utf-8"
        JSON = "application/json"
      end

      module ResponseHelpers
        def json_response(data, status : Int32 = 200, headers : Hash(String, String) = {} of String => String)
          {status, data.to_json, {"Content-Type" => MIME::JSON}.merge(headers)}
        end

        def html_response(data : String, status : Int32 = 200, headers : Hash(String, String) = {} of String => String)
          {status, data, {"Content-Type" => MIME::HTML}.merge(headers)}
        end

        def empty_response(headers : Hash(String, String) = {} of String => String)
          {204, "", headers}
        end

        def status_response(status : Int32, headers : Hash(String, String) = {} of String => String)
          {status, "", headers}
        end
      end

      macro included
        include ResponseHelpers

        @context : Ctx?

        # def self.call(app : App, context : HTTP::Server::Context, route : Tjeneste::Routing::Route)
        #   new.call_wrapper(Ctx.new(app, context), context, route)
        # end

        def self.call(app : App, context : HTTP::Server::Context, route : Tjeneste::Routing::Route)
          new(app).call_wrapper(context, route)
        end

        def initialize(@app : App)
        end

        getter app : App

        def context
          @context.not_nil!
        end

        private def with_context(ctx : Ctx)
          @context = ctx
          yield
        ensure
          @context = nil
        end

        # FIXME make sure that the router instantiates new actions every time
        def call_wrapper(http_context : HTTP::Server::Context, route : Tjeneste::Routing::Route)
          @context = Ctx.new(app, http_context)
          r = http_context.request
          params = Params.new(r.query_params.to_h.merge(route.virtual_params))

          data_str = case b = r.body
          when IO then b.gets_to_end
          else ""
          end

          data = Data.load(data_str) # FIXME handle IO and other types
          params.validate!
          data.validate!

          status, body, headers = with_context(context) do
            call(params, data)
          end

          http_context.response.status_code = status
          headers.each do |k, v|
            http_context.response.headers.add(k, v)
          end
          http_context.response.print(body)
        rescue JSON::ParseException
          http_context.response.status_code = 400
        # rescue e : Exception
        #   context.response.status_code = 500
        #   context.response.print(e.message)
        #   # context.response.print(e.backtrace)
        #   puts e.message
        #   puts e.backtrace
        # ensure
        #   context.response.close
        end
      end # included

      module Params
        include Validations

        def initialize(input : Hash(String, String))
        end

        macro mapping(**properties)
          Tjeneste::Action::Base::Params.mapping({{properties}})
        end

        macro mapping(hash)
          {% for name, type in hash %}
            getter {{name}} : {{type}}
          {% end %}

          def initialize(input : Hash(String, String))
            {% for name, kind in hash %}
              value = input["{{name}}"]
              {%
                t = kind.stringify
                assignment = {
                  "Int64"   => "value.to_i64(whitespace: false)",
                  "Int32"   => "value.to_i32(whitespace: false)",
                  "Float32" => "value.to_f32(whitespace: false)",
                  "Time"    => "value",
                  "String"  => "value",
                }[kind.stringify] || "value"
              %}
              @{{name}} = {{assignment.id}}
            {% end %}
          end

          def specification
            {{hash}}
          end
        end
      end

      module Data
        include Validations

        macro included
          def self.load(str : String)
            new # do nothing
          end
        end

        macro mapping(**properties)
          Tjeneste::Action::Base::Data.mapping({{properties}})
        end

        macro mapping(hash)
          JSON.mapping({{hash}})

          def self.load(str : String)
            from_json(str)
          end
        end
      end # Data

    end # Base
  end
end
