require "./../spec_helper"

describe Tjeneste::Middlewares::ExceptionMiddleware do
  class Sub
    alias Event = Tjeneste::Middlewares::ExceptionMiddleware::ExceptionEvent

    include Besked::Subscriber(Event)

    getter events : Array(Event)

    def initialize
      @events = [] of Event
    end

    def receive(event : Event)
      @events << event
    end
  end

  class Endpoint
    include HTTP::Handler

    def call(context : HTTP::Server::Context)
      raise("exception") if 1 > 0
    end
  end

  test "catches exception then calls callbacks and returns 500" do
    exc = nil
    sub = Sub.new
    endpoint = Endpoint.new

    m = Tjeneste::Middlewares::ExceptionMiddleware.new(endpoint,
      ->(c : HTTP::Server::Context, e : Exception) {
        exc = e
        nil
      }
    )

    m.publisher.subscribe(sub)

    resp = send_request(m, "GET", "/")
    assert resp.status_code == 500

    assert sub.events.size == 1

    exception = sub.events.first.exception
    assert exception.class == Exception
    assert exception.message == "exception"

    assert exc == exception
  end
end
