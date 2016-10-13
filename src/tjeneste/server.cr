require "http/server"
require "logger"

module Tjeneste
  class Server
    getter logger : Logger
    getter port : Int32
    getter server : HTTP::Server

    def self.new(*args, &callback : HTTP::Server::Context -> Nil)
      new(*args, callback)
    end

    def initialize(@port : Int32, @logger = Logger.new(STDOUT), &callback : HTTP::Server::Context -> Nil)
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
