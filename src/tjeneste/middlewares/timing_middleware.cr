require "../timeable"

module Tjeneste
  module Middlewares
    class TimingMiddleware(C) < Middleware
      include Timeable

      class RequestTimingEvent < EventSystem::Event
        getter context, timing, response

        def initialize(@timing, @context : C, @response)
        end
      end

      class Context # FIXME Context = C
        forward_missing_to original

        getter original

        def initialize(@original : C)
        end
      end

      getter successor

      def initialize(@successor)
      end

      def call(context : C)
        result, timing = profile do
          successor.call(Context.new(context))
        end

        EventSystem::Global.publish(TimingMiddleware, "timing", RequestTimingEvent.new(timing, context, result))
        result
      end
    end
  end
end
