require "./spec_helper"

describe Tjeneste::Middleware do
  it "responds with 404 when no middleware is chained" do
    mid = Tjeneste::TimingMiddleware.new

    req = HTTP::Request.new("GET", "/")

    assert mid.call(req).status_code == 404
  end

  it "fires a global timing event" do
    mid = Tjeneste::TimingMiddleware.new

    req = HTTP::Request.new("GET", "/")

    subscriber_notified = false

    Tjeneste::EventSystem::Global.subscribe(Tjeneste::TimingMiddleware, "timing") do |timing, req|
      subscriber_notified = true
    end

    mid.call(req)

    assert subscriber_notified
  end
end
