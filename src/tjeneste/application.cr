require "./middleware"
require "./routing/**"

module Tjeneste
  abstract class Application
    getter logger : Logger
    getter! middleware : HttpBlock

    def initialize(@logger = Logger.new(STDOUT))
      @middleware = build_middleware
    end

    abstract def build_middleware : HttpBlock
  end

  def self.run_application(app, port)
    server = HTTP::Server.new(port) do |ctx|
      app.middleware.call(ctx)
    end

    server.listen
  end
end
