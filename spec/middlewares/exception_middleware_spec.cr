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

  test "catches exception then calls callbacks and returns 500" do
    sub = Sub.new

    m = Tjeneste::Middlewares::ExceptionMiddleware.new(
      ->(c : HTTP::Server::Context) { [""][2]; nil }
    )

    m.publisher.subscribe(sub)

    resp = send_request(m, "GET", "/")
    assert resp.status_code == 500

    assert sub.events.size == 1
    assert sub.events.first.exception.class == IndexError
  end
end
