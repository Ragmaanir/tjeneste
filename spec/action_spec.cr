require "./spec_helper"

describe Tjeneste::Action do
  class SampleAction
    include Tjeneste::Action

    class Params
      include Tjeneste::Action::Params
    end

    class Data
      include Tjeneste::Action::Data

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
      data.a + data.b
    end
  end

  test "parameters are used when invoking the action" do
    req = HTTP::Request.new("GET", "/topics?id=5", nil, {a: 1000, b: 666, c: 1}.to_json)
    resp = HTTP::Server::Response.new(MemoryIO.new(1000))
    c = HTTP::Server::Context.new(req, resp)

    assert SampleAction.call(c) == 1666
  end

  test "validations fail" do
    req = HTTP::Request.new("GET", "/topics?id=5", nil, {a: -1, b: 1}.to_json)
    resp = HTTP::Server::Response.new(MemoryIO.new(1000))
    c = HTTP::Server::Context.new(req, resp)

    assert_raises(Tjeneste::Action::ValidationError) { SampleAction.call(c) }
  end
end
