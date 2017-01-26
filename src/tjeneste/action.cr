require "json"

module Tjeneste
  module Action
    class ValidationError < Exception
    end

    class Error < Exception
      getter value : String
      getter message : String?

      def initialize(@value, @message)
      end
    end

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

      def self.call(context : HTTP::Server::Context)
        new.call_wrapper(context)
      end

      # FIXME make sure that the router instantiates new actions every time
      def call_wrapper(context : HTTP::Server::Context)
        r = context.request
        params = Params.new(r.query_params)
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

          {% if block.body.is_a?(Expressions) %}
            {% for e, i in block.body.expressions %}
              res << ExpressionResult.new(({{e}}), "{{e}}")
            {% end %}
          {% else %}
            {% e = block.body %}
            res << ExpressionResult.new(({{e}}), "{{e}}")
          {% end %}

          ValidationResult.new(res)
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

    module Params
      include Validations

      def initialize(input : HTTP::Params)
      end

      macro mapping(**properties)
        Tjeneste::Action::Params.mapping({{properties}})
      end

      macro mapping(hash)
        {% for name, type in hash %}
          getter {{name}} : {{type}}
        {% end %}

        def initialize(input : HTTP::Params)
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
