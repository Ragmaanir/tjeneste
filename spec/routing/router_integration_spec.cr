require "../spec_helper"

describe Tjeneste::Routing::Router do
  test "routes requests to the associated actions" do
    results = [] of String
    router = Tjeneste::Routing::RouterBuilder.build do
      get "" do |ctx|
        results << "root"
        ctx.response.status_code = 200
      end

      path "topics" do
        post "test" do |ctx|
          results << "create"
          ctx.response.status_code = 200
        end
        get({id: /\d+/}) do |ctx|
          results << "show"
          ctx.response.status_code = 200
        end
      end
    end

    # req 1
    route!(router, "POST", "/topics/test")

    assert results == ["create"]

    # req 2
    route!(router, "GET", "/topics/1")

    assert results == ["create", "show"]

    # req 3
    route!(router, "GET", "/")

    assert results == ["create", "show", "root"]
  end
end

describe "Routing" do
  def route_for(router, method, path)
    req = HTTP::Request.new(method, path)
    router.route(req)
  end

  test "different routes" do
    router = Tjeneste::Routing::RouterBuilder.build do
      get "", Tjeneste::EmptyBlock
      path "topics" do
        get({id: /\d+/}, Tjeneste::EmptyBlock)
        put({id: /\d+/}, Tjeneste::EmptyBlock)

        path "comments" do
          get "", Tjeneste::EmptyBlock
          post "", Tjeneste::EmptyBlock
          get({id: /\d+/}, Tjeneste::EmptyBlock)
        end
      end
    end

    assert route_for(router, "GET", "/")
    assert route_for(router, "GET", "/topics/556")
    assert route_for(router, "PUT", "/topics/1337")

    assert route_for(router, "GET", "/topics/comments")
    assert route_for(router, "POST", "/topics/comments")
    assert route_for(router, "GET", "/topics/comments/45567")
  end

  test "mounting" do
    router = Tjeneste::Routing::RouterBuilder.build do
      path "public" do
        mount "assets", ->(ctx : HTTP::Server::Context) { puts "asset!" }
      end
    end

    assert route_for(router, "GET", "/public/assets/images/myimage.jpg")
    assert route_for(router, "GET", "/public") == nil
  end

  test "path parameters" do
    invocations = [] of String

    router = Tjeneste::Routing::RouterBuilder.build do
      path "topics" do
        get({id: /\d+/}) do |ctx|
          invocations << [ctx.request.path, ctx.request.query].join
          nil
        end
      end
    end

    route!(router, "GET", "/topics/12345")

    assert !route_for(router, "GET", "/topics/test")

    assert invocations == ["/topics/12345"]
  end

  test "router uses depth first search" do
    actions = [] of Symbol
    action_a = ->(ctx : HTTP::Server::Context) { actions << :action_a; nil }
    action_b = ->(ctx : HTTP::Server::Context) { actions << :action_b; nil }

    router = Tjeneste::Routing::RouterBuilder.build do
      path "topics" do
        get "", action_a
      end

      get "", action_b
    end

    route!(router, "GET", "/topics")

    assert actions == [:action_a]
  end
end

describe "Actions" do
  APP = 1337

  class Context
    getter app : Int32
    getter http_context : HTTP::Server::Context

    def initialize(@app, @http_context)
    end
  end

  class SampleAction
    include Tjeneste::Action::Base(Int32, Context)

    class Params
      include Tjeneste::Action::Base::Params

      mapping(
        a: Int32,
        b: Int32,
      )

      validations do
        a >= 0
        b > 0 && b <= 1000
      end
    end

    class Data
      include Tjeneste::Action::Base::Data
    end

    def call(params : Params, data : Data)
      params.validate!
      json_response(app + params.a + params.b)
    end
  end

  test "returns route with action" do
    router = Tjeneste::Routing::RouterBuilder.build(APP, Int32, Context) do
      path "topics" do
        get "", SampleAction.new(APP)
      end
    end

    req = HTTP::Request.new("GET", "/topics")

    route = router.route!(req)
    assert route.action.is_a?(Tjeneste::Action::AbstractAction)
    assert route.action.class == SampleAction # FIXME crystal bug
  end

  test "action receives path-parameters" do
    router = Tjeneste::Routing::RouterBuilder.build(APP, Int32, Context) do
      path "topics" do
        get({a: /\d+/}, SampleAction)
      end
    end

    resp, ctx = lazy_request("GET", "/topics/1337?b=5")

    route = router.route!(ctx.request)

    route.call_action(ctx)

    assert resp.call.body == (APP + 1337 + 5).to_s
  end
end

# module MountEndpoint
#   class MyEndpoint
#     def call(ctx : HTTP::Server::Context)
#       ctx.response.status_code = 200
#       ctx.response.puts "MyEndpoint"
#       ctx.response.close
#     end
#   end

#   describe MountEndpoint do
#     test "calls the enpoint" do
#       router = Tjeneste::Routing::RouterBuilder.build do |r|
#         r.path "backend" do |r|
#           r.path "topics" do |r|
#             r.get :int, MyEndpoint
#           end
#         end
#       end

#       req = HTTP::Request.new("GET", "/backend/topics/1337")
#       response_body = MemoryIO.new
#       ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(response_body))
#       route = router.route!(req)
#       route.action.call(ctx)
#       response_body.rewind
#       resp = HTTP::Client::Response.from_io(response_body)
#       assert resp.body == "MyEndpoint\n"
#     end
#   end
# end

# module MountMiddleware
#   class MyMiddleware
#     def initialize(@param : String)
#     end

#     def call(ctx : HTTP::Server::Context)
#       ctx.response.status_code = 200
#       ctx.response.puts "#{ctx.request.path}, #{ctx.request.method}, #{@param}"
#       ctx.response.close
#     end
#   end

#   describe MountMiddleware do
#     test "gets called with any method and any remaining path" do
#       router = Tjeneste::Routing::RouterBuilder.build do |r|
#         r.path "topics" do |r|
#           r.mount "all", MyMiddleware, "some_param"
#         end
#       end

#       req = HTTP::Request.new("XYZ", "/topics/all/extra_path")
#       response_body = MemoryIO.new
#       ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(response_body))
#       route = router.route!(req)
#       route.action.call(ctx)
#       response_body.rewind
#       resp = HTTP::Client::Response.from_io(response_body)
#       assert resp.body == "/topics/all/extra_path, XYZ, some_param\n"
#     end
#   end
# end
