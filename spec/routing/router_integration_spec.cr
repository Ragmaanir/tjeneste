require "../spec_helper"

describe Tjeneste::Routing::Router do
  it "routes requests to the associated actions" do
    results = [] of String
    router = Tjeneste::Routing::RouterBuilder.build do |r|
      r.path "topics" do |r|
        r.post "", ->(_ctx : HTTP::Request) { results << "create"; HTTP::Response.new(200) }
        r.get :int, ->(_ctx : HTTP::Request) { results << "show"; HTTP::Response.new(200) }
      end
    end

    # req 1
    req = HTTP::Request.new("POST", "topics/")

    route = router.route!(req)

    route.action.call(req)

    assert results == ["create"]

    # req 2
    req = HTTP::Request.new("GET", "topics/1")

    route = router.route!(req)

    route.action.call(req)

    assert results == ["create", "show"]
  end
end

module Spec1

  class MyEndpoint
    def call(req : HTTP::Request)
      HTTP::Response.new(200, "MyEndpoint")
    end
  end

  describe Spec1 do
    it "" do
      router = Tjeneste::Routing::RouterBuilder.build do |r|
        r.path "backend" do |r|
          r.path "topics" do |r|
            r.get :int, MyEndpoint
          end
        end
      end

      req = HTTP::Request.new("GET", "backend/topics/1337")
      route = router.route!(req)
      assert route.action.call(req).body == "MyEndpoint"
    end
  end
end
