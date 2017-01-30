require "json"

require "./action/validation"

module Tjeneste
  module Action
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
