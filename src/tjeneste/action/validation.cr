module Tjeneste
  module Action
    class ValidationError < Exception
    end

    # class Error < Exception
    #   getter value : String
    #   getter message : String?

    #   def initialize(@value, @message)
    #   end
    # end

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
        def validate : Tjeneste::Action::ValidationResult
          res = [] of Tjeneste::Action::ExpressionResult

          {% if block.body.is_a?(Expressions) %}
            {% for e, i in block.body.expressions %}
              res << Tjeneste::Action::ExpressionResult.new(({{e}}), "{{e}}")
            {% end %}
          {% else %}
            {% e = block.body %}
            res << Tjeneste::Action::ExpressionResult.new(({{e}}), "{{e}}")
          {% end %}

          Tjeneste::Action::ValidationResult.new(res)
        end

        def expressions
          if !@expressions
            exps = [] of String

            {% if block.body.is_a?(Expressions) %}
              {% for e, i in block.body.expressions %}
                exps << "{{e}}"
              {% end %}
            {% else %}
              {% e = block.body %}
              exps << "{{e}}"
            {% end %}

            @expressions = exps
          end
          @expressions
        end
      end
    end
  end
end
