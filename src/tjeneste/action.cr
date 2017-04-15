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

    class LazyAction(A) < AbstractLazyAction
      getter context : A
      getter action_factory : A -> Action::AbstractAction

      def initialize(@context : A, &@action_factory : A -> Action::AbstractAction)
      end

      def call(ctx : HTTP::Server::Context, route : Tjeneste::Routing::Route)
        @action_factory.call(@context).call_wrapper(ctx, route)
      end
    end

    module AbstractAction
    end

    module Base(A)
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
      end

      macro included
        include ResponseHelpers

        getter context : A

        def initialize(@context : A)
        end

        def self.call(ctx : A, context : HTTP::Server::Context, route : Tjeneste::Routing::Route)
          new(ctx).call_wrapper(context, route)
        end

        # FIXME make sure that the router instantiates new actions every time
        def call_wrapper(context : HTTP::Server::Context, route : Tjeneste::Routing::Route)
          r = context.request
          params = Params.new(r.query_params.to_h.merge(route.virtual_params))
          data = Data.load(r.body.to_s || "") # FIXME handle IO and other types
          params.validate!
          data.validate!

          status, body, headers = call(params, data)

          context.response.status_code = status
          headers.each do |k, v|
            context.response.headers.add(k, v)
          end
          context.response.print(body)
          context.response.close
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

          def self.load(str : String)
            from_json(str)
          end
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
