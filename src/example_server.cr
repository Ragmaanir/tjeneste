require "./tjeneste"

class HomeAction
  include Tjeneste::Action

  class Params
    include Tjeneste::Action::Params
  end

  class Data
    include Tjeneste::Action::Data
  end

  def call(params : Params, data : Data)
  end
end

class App < Tjeneste::Application
  def build_middleware
    router = Tjeneste::Routing::RouterBuilder.build do |r|
      r.get "status" do |ctx|
        ctx.response.status_code = 200
        ctx.response.puts "OK"
        ctx.response.close
      end
      r.get "", HomeAction.new
    end

    Tjeneste::Middlewares::RoutingMiddleware.new(router)
  end
end

App.new.run
