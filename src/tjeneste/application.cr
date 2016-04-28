require "./server"
require "./middleware"
require "./http_context"
require "./routing/**"

module Tjeneste
  abstract class Application

    getter logger

    def initialize(@port : Int = 3000, @logger : Logger = Logger.new(STDOUT))
      @middleware_stack = build_middleware

      @server = Tjeneste::Server.new(@port, @logger, ->(ctx : HTTP::Server::Context) {
        @middleware_stack.call(HttpContext.new(ctx))
      })
    end

    abstract def build_middleware : Middleware

    def run
      @server.start
    end
  end
end
