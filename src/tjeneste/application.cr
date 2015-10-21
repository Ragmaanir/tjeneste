require "./server"
require "./middleware"
require "./http_context"
require "./routing/**"

module Tjeneste
  abstract class Application
    def initialize(@port = 3000 : Int, @logger = Logger.new(STDOUT) : Logger)
      @middleware_stack = build_middleware

      @server = Tjeneste::Server.new(@port, @logger, ->(req : HTTP::Request) {
        @middleware_stack.call(HttpContext.new(req))
      })

      EventSystem::Global.subscribe(Tjeneste::TimingMiddleware, "timing") do |obj, name, event|
        te = event as Tjeneste::TimingMiddleware::RequestTimingEvent
        logger.info "#{te.timing.milliseconds}ms : #{te.response.status_code} : \t#{te.context.request.method} #{te.context.request.path}"
      end

      EventSystem::Global.subscribe(Tjeneste::ExceptionMiddleware, "exception") do |obj, name, event|
        ee = event as Tjeneste::ExceptionMiddleware::ExceptionEvent
        logger.error "#{ee.exception.message} (#{ee.exception.backtrace.join("\n")})"
      end
    end

    abstract def build_middleware : Middleware

    def run
      @server.start
    end
  end
end

class TestApp < Tjeneste::Application
  include Tjeneste::MiddlewareBuilder

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

    # Tjeneste::TimingMiddleware.new(
    #   Tjeneste::HeaderMiddleware.new(
    #     {"Content-Security-Policy" => "script-src 'self'"},
    #     Tjeneste::ExceptionMiddleware.new(
    #       Tjeneste::RoutingEndpoint.new(router)
    #     )
    #   )
    # )

    define_middleware_stack({
      Tjeneste::TimingMiddleware => Tuple.new(),
      Tjeneste::ExceptionMiddleware => Tuple.new(),
      Tjeneste::RoutingEndpoint => Tuple.new(router)
    })
  end

  # macro define_middleware_stack(*classes)
  #   {% for c, idx in classes %}
  #     {% if idx == 0 %}
  #       {{c}}(Tjeneste::HttpContext).new(
  #     {% elsif idx == classes.size - 1 %}
  #       {{c}}({{classes[idx-1]}}::Context).new(
  #     {% else %}
  #       {{c}}({{classes[idx-1]}}::Context).new(
  #     {% end %}
  #   {% end %}
  #   {% for c, idx in classes %}
  #   )
  #   {% end %}
  # end

end

#TestApp.new.run
