require "json"

module Tjeneste
  module Action
    class ValidationError < Exception
    end

    macro included
      def self.call(context : HTTP::Server::Context)
        new.call_wrapper(context)
      end

      # FIXME make sure that the router instantiates new actions every time
      def call_wrapper(context : HTTP::Server::Context)
        r = context.request
        params = Params.new(r.query_params)
        data = Data.from_json(r.body || "")
        params.validate!
        data.validate!
        call(params, data)
      end
    end

    module Params
      def initialize(input : HTTP::Params)
      end

      def validate!
        raise("") if !valid?
      end

      def valid?
        true
      end

      macro mapping(**properties)
        Tjeneste::Action::Params.mapping({{properties}})
      end

      macro mapping(hash)
        def initialize(input : HTTP::Params)
          specification.map do |name,kind|
            value = input[name]
            case kind
            when Int32 then value.first.to_i32(whitespace: false) { Error.new(value, "Is not an integer") }
            when Float32 then value.first.to_f32(whitespace: false) { Error.new(value, "Is not a float") }
            when DateTime
            when String
            end
          end
        end

        def specification
          {{hash}}
        end
      end
    end

    module Data
      def validate!
        raise("") if !valid?
      end

      def valid?
        true
      end

      macro mapping(**properties)
        Tjeneste::Action::Data.mapping({{properties}})
      end

      macro mapping(hash)
        JSON.mapping({{hash}})
      end

      class ValidationResult
        getter results : Array(ExpressionResult)

        def initialize(@results)
        end

        def errors
          results.select(&.error?)
        end

        def display
          results.map(&.display).join("\n")
        end
      end

      class ExpressionResult
        getter expression : String

        def initialize(@passed : Bool, @expression)
        end

        def passed?
          @passed
        end

        def error?
          !passed?
        end

        def display
          b = passed? ? "\u2713".colorize(:green) : "\u2715".colorize(:red)
          "#{b} : #{expression}"
        end
      end

      macro validations(&block)
        def validate
          res = [] of ExpressionResult
          {% for e, i in block.body.expressions %}
            res << ExpressionResult.new(({{e}}), "{{e}}")
          {% end %}
          ValidationResult.new(res)
        end

        def expressions
          if !@expressions
            exps = [] of String
            {% for e, i in block.body.expressions %}
              exps << "{{e}}"
            {% end %}
            @expressions = exps
          end
          @expressions
        end
      end
    end # Data

  end
end
