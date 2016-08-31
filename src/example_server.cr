require "./tjeneste"

class TestApp < Tjeneste::Application
  include Tjeneste::MiddlewareBuilder

  def initialize(*args)
    super

    Tjeneste::EventSystem::Global.subscribe(Tjeneste::Middlewares::TimingMiddleware, "timing") do |obj, name, event|
      te = event.as(Tjeneste::Middlewares::TimingMiddleware::RequestTimingEvent)
      logger.info "#{te.timing.milliseconds}ms : #{te.response.status_code} : \t#{te.context.request.method} #{te.context.request.path}"
    end

    Tjeneste::EventSystem::Global.subscribe(Tjeneste::Middlewares::ExceptionMiddleware, "exception") do |obj, name, event|
      ee = event.as(Tjeneste::Middlewares::ExceptionMiddleware::ExceptionEvent)
      logger.error "#{ee.exception.message} (#{ee.exception.backtrace.join("\n")})"
    end
  end

  def build_middleware
    router = Tjeneste::Routing::RouterBuilder.build do |r|
      r.get "status", ->(ctx : HTTP::Server::Context) {
        raise "Some error" if rand > 0.5
        ctx.response.status_code = 200
        ctx.response.puts "OK"
        ctx.response.close
      }
      r.get "", MyEndpoint
    end

    define_middleware_stack({
      Tjeneste::Middlewares::TimingMiddleware    => Tuple.new,
      Tjeneste::Middlewares::ExceptionMiddleware => Tuple.new,
      Tjeneste::Middlewares::HeaderMiddleware    => Tuple.new({"Content-Security-Policy" => "script-src 'self'"}),
      Tjeneste::Middlewares::SessionMiddleware   => Tuple.new("session_id"),
      Tjeneste::Routing::RoutingEndpoint         => Tuple.new(router),
    })
  end

  class MyEndpoint < Tjeneste::Routing::Endpoint
    def call(ctx)
      ctx.response.status_code = 200
      ctx.response.puts "All working"
      ctx.response.close
    end
  end
end

TestApp.new.run
