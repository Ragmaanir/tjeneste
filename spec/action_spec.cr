require "./spec_helper"

describe Tjeneste::Action do
  APP = 1337

  class SampleAction
    include Tjeneste::Action::Base(Int32)

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
      json_response(data.a + data.b)
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

    SampleAction.call(APP, c, empty_route(SampleAction.new(APP)))
    io.rewind
    resp = HTTP::Client::Response.from_io(io)
    assert resp.body == "1666"
  end

  test "validations fail" do
    req = HTTP::Request.new("GET", "/topics?id=5", nil, {a: -1, b: 1}.to_json)
    resp = HTTP::Server::Response.new(IO::Memory.new(1000))
    c = HTTP::Server::Context.new(req, resp)

    assert_raises(Tjeneste::Action::ValidationError) { SampleAction.call(APP, c, empty_route(SampleAction.new(APP))) }
  end
end
