module Tjeneste
  module Timeable
    class TimingEvent < EventSystem::Event
      getter :timing

      def initialize(@timing)
      end

      def to_s
        "#{timing.start} (#{timing.milliseconds}ms)"
      end
    end

    class Timing
      getter :start, :stop

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
