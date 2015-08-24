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
    req = HTTP::Request.new("POST", "/topics/")

    route = router.route!(req)

    route.action.call(req)

    assert results == ["create"]

    # req 2
    req = HTTP::Request.new("GET", "/topics/1")

    route = router.route!(req)

    route.action.call(req)

    assert results == ["create", "show"]
  end
end

module MountEndpoint

  class MyEndpoint
    def call(req : HTTP::Request)
      HTTP::Response.new(200, "MyEndpoint")
    end
  end

  describe MountEndpoint do
    it "" do
      router = Tjeneste::Routing::RouterBuilder.build do |r|
        r.path "backend" do |r|
          r.path "topics" do |r|
            r.get :int, MyEndpoint
          end
        end
      end

      req = HTTP::Request.new("GET", "/backend/topics/1337")
      route = router.route!(req)
      assert route.action.call(req).body == "MyEndpoint"
    end
  end
end

module MountMiddleware

  class MyMiddleware
    def initialize(@param)
    end

    def call(req : HTTP::Request)
      HTTP::Response.new(200, "#{req.path}, #{req.method}, #{@param}")
    end
  end

  describe MountMiddleware do
    it "gets called with any method and any remaining path" do
      router = Tjeneste::Routing::RouterBuilder.build do |r|
        r.path "topics" do |r|
          r.mount "all", MyMiddleware, "some_param"
        end
      end

      req = HTTP::Request.new("XYZ", "/topics/all/extra_path")
      route = router.route!(req)
      assert route.action.call(req).body == "/topics/all/extra_path, XYZ, some_param"
    end
  end
end
