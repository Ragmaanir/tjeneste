require "json"
require "http"

module Tjeneste
  module Action(A)
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
        Tjeneste::Action::Params.mapping({{properties}})
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
        Tjeneste::Action(A)::Data.mapping({{properties}})

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

class SampleAction
  include Tjeneste::Action(Int32)

  def initialize(@v : Int32)
  end

  class Params
    include Tjeneste::Action::Params
  end

  class Data
    include Tjeneste::Action::Data

    mapping(
      a: Int32,
      b: Int32,
    )
  end

  def call(params : Params, data : Data)
    # data.validate!
    json_response(data.a + data.b)
  end
end

# def empty_route(action)
#   Routing::Route.new([] of Routing::Node, action, {} of String => String)
# end

req = HTTP::Request.new("GET", "/topics?id=5", nil, {a: 1000, b: 666, c: 1}.to_json)
io = IO::Memory.new(1000)
resp = HTTP::Server::Response.new(io)
c = HTTP::Server::Context.new(req, resp)

# SampleAction.call(c, empty_route(SampleAction.new))
SampleAction.call(1337, c)
io.rewind
resp = HTTP::Client::Response.from_io(io)
p resp.body == "1666"
