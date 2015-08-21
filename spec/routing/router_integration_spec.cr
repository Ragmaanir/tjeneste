require "../spec_helper"

describe Tjeneste::Routing::Router do
  it "" do
    results = [] of String
    router = Tjeneste::Routing::RouterBuilder.build do |r|
      r.path "topics" do |r|
        r.post "", ->(_ctx : Tjeneste::Routing::HttpContext) { results << "create"; nil }
        r.get :int, ->(_ctx : Tjeneste::Routing::HttpContext) { results << "show"; nil }
      end
    end

    # req 1
    req = HTTP::Request.new("POST", "topics/")

    route = router.route!(req)

    ctx = Tjeneste::Routing::HttpContext.new(req)
    (route.action as Tjeneste::Routing::HttpContext -> Nil).call(ctx)

    assert results == ["create"]

    # req 2
    req = HTTP::Request.new("GET", "topics/1")

    route = router.route!(req)

    ctx = Tjeneste::Routing::HttpContext.new(req)
    (route.action as Tjeneste::Routing::HttpContext -> Nil).call(ctx)

    assert results == ["create", "show"]
  end

  # it "" do
  #   class MyEndpoint
  #     def call(context : Tjeneste::Routing::HttpContext)
  #     end
  #   end

  #   router = Tjeneste::Routing::RouterBuilder.build do |r|
  #     r.path "backend" do |r|
  #       r.path "topics" do |r|
  #         get :int, MyEndpoint
  #       end
  #     end
  #   end

  #   req = HTTP::Request.new("GET", "backend/topics/1337")
  #   route = router.route!(req)
  # end
end
