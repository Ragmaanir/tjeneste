require "./spec_helper"

describe Tjeneste::Application do
  class Context
  end

  class App < Tjeneste::Application
    def build_middleware
      router = build_router

      ->(c : HTTP::Server::Context) {
        Tjeneste::Middlewares::RoutingMiddleware.new(router).call(c)
        nil
      }
    end

    def build_router
      Tjeneste::Routing::RouterBuilder.build(self, Application, Context) do
        get "" do |c|
          c.response.status_code = 200
        end

        # mount "", Tjeneste::StaticFileHandler.new("./public")
      end
    end
  end

  test "middleware responds correctly" do
    app = App.new

    resp = send_request(app.middleware, "GET", "/")
    assert resp.status_code == 200

    resp = send_request(app.middleware, "GET", "/test")
    assert resp.status_code == 404
  end
end
