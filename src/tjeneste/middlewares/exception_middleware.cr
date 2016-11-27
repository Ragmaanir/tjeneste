module Tjeneste
  module Middlewares
    class ExceptionMiddleware
      struct ExceptionEvent
        getter exception : Exception
        getter context : HTTP::Server::Context

        def initialize(@context : HTTP::Server::Context, @exception : Exception)
        end
      end

      class Publisher
        include Besked::Publisher(ExceptionEvent)
      end

      DEFAULT_CALLBACK = ->(c : HTTP::Server::Context, e : Exception) {
        c.response.status_code = 500
        c.response.puts "Internal Server Error"
        c.response.close
        nil
      }

      getter successor : HttpBlock
      getter publisher : Publisher

      def initialize(@successor, @callback : (HTTP::Server::Context, Exception) -> Nil = DEFAULT_CALLBACK, @publisher : Publisher = Publisher.new)
      end

      def call(context : HTTP::Server::Context)
        @successor.call(context)
      rescue exception : Exception
        @callback.call(context, exception)
        @publisher.publish(ExceptionEvent.new(context, exception))
      end
    end
  end
end
