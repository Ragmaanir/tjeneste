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
        get :int do |ctx|
          results << "show"
          ctx.response.status_code = 200
        end
      end
    end

    # req 1
    req = HTTP::Request.new("POST", "/topics/test")
    ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(IO::Memory.new("")))

    route = router.route!(req)

    route.action.as(Tjeneste::HttpBlock).call(ctx)

    assert results == ["create"]

    # req 2
    req = HTTP::Request.new("GET", "/topics/1")
    ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(IO::Memory.new("")))

    route = router.route!(req)

    route.action.as(Tjeneste::HttpBlock).call(ctx)

    assert results == ["create", "show"]

    # req 3
    req = HTTP::Request.new("GET", "/")
    ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(IO::Memory.new("")))

    route = router.route!(req)

    route.action.as(Tjeneste::HttpBlock).call(ctx)

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
        get :int, Tjeneste::EmptyBlock
        put :int, Tjeneste::EmptyBlock

        path "comments" do
          get "", Tjeneste::EmptyBlock
          post "", Tjeneste::EmptyBlock
          get :int, Tjeneste::EmptyBlock
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

  # test! "path parameters" do
  #   router = Tjeneste::Routing::RouterBuilder.build do
  #     path "topics" do
  #       get :id, //, action_a
  #     end

  #     get "", action_b
  #   end
  # end

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

    req = HTTP::Request.new("GET", "/topics")
    ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(IO::Memory.new("")))

    m = Tjeneste::Middlewares::RoutingMiddleware.new(router)
    m.call(ctx)

    assert actions == [:action_a]
  end
end

describe "Actions" do
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
      json_response(data.a + data.b)
    end
  end

  test "returns route with action" do
    router = Tjeneste::Routing::RouterBuilder.build do
      path "topics" do
        get "", SampleAction.new
      end
    end

    req = HTTP::Request.new("GET", "/topics")

    route = router.route!(req)
    assert route.action.is_a?(SampleAction)
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
