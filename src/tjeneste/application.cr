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
