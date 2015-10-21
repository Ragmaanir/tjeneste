require "./event_system"

module Tjeneste
  module Timeable
    class Timing
      getter :timespan, :start, :stop

      forward_missing_to timespan

      def initialize(@start, @stop)
        @timespan = stop - start
      end

      def milliseconds
        @timespan.milliseconds
      end
    end

    class TimingEvent < EventSystem::Event
      @timing :: Timing
      getter :timing

      def initialize(@timing)
      end

      def to_s
        "#{timing.start} (#{timing.milliseconds}ms)"
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
