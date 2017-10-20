module Tjeneste
  module Middlewares
    class ExceptionMiddleware
      include HTTP::Handler

      class ExceptionEvent
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

      getter! next : HTTP::Handler
      getter callback : (HTTP::Server::Context, Exception) -> Nil
      getter publisher : Publisher

      def initialize(@next, @callback = DEFAULT_CALLBACK, @publisher : Publisher = Publisher.new)
      end

      def call(context : HTTP::Server::Context)
        call_next(context)
      rescue exception : Exception
        context.response.status_code = 500
        context.response.puts "Internal Server Error"
        context.response.close

        @callback.call(context, exception)
        @publisher.publish(ExceptionEvent.new(context, exception))
      end
    end # ExceptionMiddleware
  end
end
