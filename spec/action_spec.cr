require "./spec_helper"

describe Tjeneste::Action do
  APP = 1337

  class Context
    getter app : Int32
    getter http_context : HTTP::Server::Context

    def initialize(@app, @http_context)
    end

    def session
      1
    end
  end

  class SampleAction
    include Tjeneste::Action::Base(Int32, Context)

    class Params
      include Tjeneste::Action::Base::Params
    end

    class Data
      include Tjeneste::Action::Base::Data

      mapping(
        a: Int32,
        b: Int32,
      )

      validations do
        a >= 0
        b > 0 && b <= 1000
      end
    end

    def call(params : Params, data : Data)
      data.validate!
      json_response(context.session + data.a + data.b)
    end
  end

  def empty_route(action)
    Routing::Route.new([] of Routing::Node, action, {} of String => String)
  end

  test "parameters are used when invoking the action" do
    req = HTTP::Request.new("GET", "/topics?id=5", nil, {a: 1000, b: 666, c: 1}.to_json)
    io = IO::Memory.new(1000)
    resp = HTTP::Server::Response.new(io)
    c = HTTP::Server::Context.new(req, resp)

    # SampleAction.new.call(APP, c, empty_route(SampleAction.new))
    SampleAction.new(APP).call_wrapper(c, empty_route(SampleAction.new(APP)))
    resp.close
    io.rewind
    resp = HTTP::Client::Response.from_io(io)
    assert resp.body == "1667"
  end

  test "validations fail" do
    req = HTTP::Request.new("GET", "/topics?id=5", nil, {a: -1, b: 1}.to_json)
    io = IO::Memory.new(1000)
    resp = HTTP::Server::Response.new(io)
    c = HTTP::Server::Context.new(req, resp)

    assert_raises(Tjeneste::Action::ValidationError) do
      # SampleAction.new.call(APP, c, empty_route(SampleAction.new))
      SampleAction.new(APP).call_wrapper(c, empty_route(SampleAction.new(APP)))
    end
  end
end
