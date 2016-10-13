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
        data = Data.load(r.body || "")
        params.validate!
        data.validate!
        call(params, data)
      end
    end # included

    class ValidationResult
      getter results : Array(ExpressionResult)

      def initialize(@results)
      end

      def errors
        results.select(&.error?)
      end

      def errors?
        !passed?
      end

      def passed?
        errors.empty?
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

    module Validations
      def validate
        ValidationResult.new([] of ExpressionResult)
      end

      def validate!
        res = validate

        raise ValidationError.new if res.errors?
      end

      macro validations(&block)
        def validate : ValidationResult
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
    end

    module Params
      include Validations

      def initialize(input : HTTP::Params)
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
      include Validations

      macro included
        def self.load(str : String)
          new # do nothing
        end
      end

      macro mapping(**properties)
        Tjeneste::Action::Data.mapping({{properties}})

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

  end
end
