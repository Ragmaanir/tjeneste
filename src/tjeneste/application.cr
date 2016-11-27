require "./server"
require "./middleware"
require "./routing/**"

module Tjeneste
  abstract class Application
    getter logger : Logger
    getter middleware_stack : HttpBlock

    def initialize(@port : Int32 = 3000, @logger = Logger.new(STDOUT))
      @middleware_stack = build_middleware

      @server = Tjeneste::Server.new(@port, @logger) do |ctx|
        @middleware_stack.call(ctx)
      end
    end

    abstract def build_middleware : HttpBlock

    def run
      @server.start
    end
  end
end
