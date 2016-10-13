require "besked"

module Tjeneste
  module Middlewares
    class ExceptionMiddleware(C) < Middleware
      # class ExceptionEvent < EventSystem::Event
      #   getter exception

      #   def initialize(@exception, @context : C)
      #   end
      # end

      class Context # FIXME Context = C
        forward_missing_to original

        getter original

        def initialize(@original : C)
        end
      end

      def initialize(@successor)
      end

      getter successor

      def call(context : C)
        successor.call(Context.new(context))
      rescue e
        # EventSystem::Global.publish(ExceptionMiddleware, "exception", ExceptionEvent.new(e, context))
        context.response.status_code = 500
        context.response.puts "Internal Server Error"
        context.response.close
      end
    end
  end
end
