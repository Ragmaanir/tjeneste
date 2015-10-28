module Tjeneste
  module Middlewares
    class ExceptionMiddleware(C) < Middleware

      class ExceptionEvent < EventSystem::Event
        getter :exception

        def initialize(@exception, @context : C)
        end
      end

      class Context # FIXME Context = C
        forward_missing_to original

        getter original

        def initialize(@original : C)
        end
      end

      def initialize(@successor)
      end

      getter successor

      def call(context : C) : HTTP::Response
        successor.call(Context.new(context))
      rescue e
        EventSystem::Global.publish(ExceptionMiddleware, "exception", ExceptionEvent.new(e, context))
        HTTP::Response.new(500, "Internal Server Error")
      end
    end
  end
end
