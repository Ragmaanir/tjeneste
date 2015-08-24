require "http/request"
require "./timeable"

module Tjeneste
  abstract class Middleware
    getter :next

    def initialize(@next = nil)
    end

    def call(req : HTTP::Request) : HTTP::Response
      if @next
        (@next as Middleware).call(req)
      else
        HTTP::Response.not_found
      end
    end
  end

  class TimingMiddleware < Middleware
    include Timeable

    class RequestTimingEvent < EventSystem::Event
      getter :request, :timing

      def initialize(@timing, @request)
      end

      def to_s
        "#{timing.start} (#{timing.milliseconds}ms): #{request.method} #{request.path}"
      end
    end

    def call(req : HTTP::Request) : HTTP::Response
      response, timing = profile do
        super
      end

      EventSystem::Global.publish(self.class, "timing", RequestTimingEvent.new(timing, req))

      response
    end
  end

  class RoutingMiddleware < Middleware
    getter :router

    def initialize(@router : Routing::Router)
    end

    def call(req : HTTP::Request) : HTTP::Response
      route = router.route!(req)

      route.action.call(req)
    rescue
      HTTP::Response.not_found
    end
  end

end
