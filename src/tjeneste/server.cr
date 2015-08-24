require "http/server"
require "logger"

module Tjeneste
  class Server
    property :logger
    getter :port, :server

    def initialize(@port : Int32, @logger = Logger.new(STDOUT) : Logger, callback = ->(_req){ HTTP::Response.not_found } : HTTP::Request -> HTTP::Response )
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
