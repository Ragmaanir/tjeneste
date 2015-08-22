require "http/server"
require "logger"

module Tjeneste
  class Server
    property :logger
    property :port, :server

    def initialize(@port : Int32, @logger = Logger.new(STDOUT) : Logger)
      @server = HTTP::Server.new(@port) do |request|
        response, timing = profile do
          HTTP::Response.ok "text/plain", "Hello world! The time is #{Time.now}"
        end

        logger.info "#{timing.start} (#{timing.milliseconds}ms): #{request.method} #{request.path}"

        response
      end
    end

    def start
      logger.info "Starting server listening on 0.0.0.0:#{port}"
      server.listen
    end

    class Timing
      property :start, :stop

      # FIXME BUG segfault
      #forward_missing_to timespan

      def initialize(@start, @stop)
        @timespan = stop - start
      end

      def milliseconds
        @timespan.milliseconds
      end
    end

    private def profile
      start = Time.now
      result = yield
      stop = Time.now
      {result, Timing.new(start, stop)}
    end

  end
end

#server = Tjeneste::Server.new(8080)
#server.start
