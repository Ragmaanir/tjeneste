require "./server"
require "./middleware"
require "./routing/**"

module Tjeneste
  abstract class Application
    def initialize(@port = 3000 : Int, @logger = Logger.new(STDOUT) : Logger)
      @middleware_stack = build_middleware

      @server = Tjeneste::Server.new(@port, @logger, ->(req : HTTP::Request) {
        @middleware_stack.call(req)
      })

      EventSystem::Global.subscribe(Tjeneste::TimingMiddleware, "timing") do |obj, name, event|
        te = event as Tjeneste::TimingMiddleware::RequestTimingEvent
        logger.info "#{te.timing.milliseconds}ms \t#{te.request.method} #{te.request.path}"
      end
    end

    abstract def build_middleware : Middleware

    def run
      @server.start
    end
  end
end

# class TestApp < Tjeneste::Application
#   def build_middleware
#     router = Tjeneste::Routing::RouterBuilder.build do |r|
#       r.get "status", ->(req : HTTP::Request) {
#         HTTP::Response.new(200, "100% Ok")
#       }
#       r.path "random" do |r|
#         r.get :int, ->(req : HTTP::Request) { HTTP::Response.new(200, rand.to_s) }
#       end
#     end

#     Tjeneste::TimingMiddleware.new(Tjeneste::RoutingMiddleware.new(router))
#   end
# end

# TestApp.new.run
