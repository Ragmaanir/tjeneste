require "http/server"
require "logger"

module Tjeneste
  class Server
    property :logger
    getter :port, :server

    def self.new(*args, &callback : HTTP::Request -> HTTP::Response)
      new(*args, callback)
    end

    def initialize(@port : Int32, @logger : Logger = Logger.new(STDOUT), callback : HTTP::Request -> HTTP::Response = ->(_req){ HTTP::Response.not_found })
      @server = HTTP::Server.new(@port) do |req|
        callback.call(req)
      end
    end

    def start
      logger.info "Starting server listening on 0.0.0.0:#{port}"
      server.listen
    end

  end
end
