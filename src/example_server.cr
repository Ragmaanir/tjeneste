require "./tjeneste"

class TestApp < Tjeneste::Application
  include Tjeneste::MiddlewareBuilder

  def initialize(*args)
    super

    Tjeneste::EventSystem::Global.subscribe(Tjeneste::TimingMiddleware, "timing") do |obj, name, event|
      te = event as Tjeneste::TimingMiddleware::RequestTimingEvent
      logger.info "#{te.timing.milliseconds}ms : #{te.response.status_code} : \t#{te.context.request.method} #{te.context.request.path}"
    end

    Tjeneste::EventSystem::Global.subscribe(Tjeneste::ExceptionMiddleware, "exception") do |obj, name, event|
      ee = event as Tjeneste::ExceptionMiddleware::ExceptionEvent
      logger.error "#{ee.exception.message} (#{ee.exception.backtrace.join("\n")})"
    end
  end

  def build_middleware
    router = Tjeneste::Routing::RouterBuilder.build do |r|
      r.get "status", ->(req : HTTP::Request) {
        raise "Some error" if rand > 0.5
        HTTP::Response.new(200, "100% Ok")
      }
      r.get "", ->(req : HTTP::Request) {
        HTTP::Response.new 200, <<-HTML
          <html>
            <head>
              <script src="https://google.de/xyz.js">
              </script>
            </head>
            <body>
              <em>#{rand.to_s}</em>
            </body>
          </html>
        HTML
      }
    end

    define_middleware_stack({
      Tjeneste::TimingMiddleware => Tuple.new(),
      Tjeneste::ExceptionMiddleware => Tuple.new(),
      Tjeneste::HeaderMiddleware => Tuple.new({"Content-Security-Policy" => "script-src 'self'"}),
      Tjeneste::SessionMiddleware => Tuple.new("session_id"),
      Tjeneste::RoutingEndpoint => Tuple.new(router)
    })
  end

end

TestApp.new.run
