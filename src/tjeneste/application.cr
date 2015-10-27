require "./server"
require "./middleware"
require "./http_context"
require "./routing/**"

module Tjeneste
  abstract class Application

    getter logger
    
    def initialize(@port = 3000 : Int, @logger = Logger.new(STDOUT) : Logger)
      @middleware_stack = build_middleware

      @server = Tjeneste::Server.new(@port, @logger, ->(req : HTTP::Request) {
        @middleware_stack.call(HttpContext.new(req))
      })
    end

    abstract def build_middleware : Middleware

    def run
      @server.start
    end
  end
end
