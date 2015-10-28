require "./spec_helper"

describe Tjeneste::Middleware do
  it "responds with 404 when no middleware is chained" do
    # mid = Tjeneste::TimingMiddleware(Tjeneste::TimingMiddleware::Context -> HTTP::Response).new(
    #   ->(c : Tjeneste::TimingMiddleware::Context){ HTTP::Response.not_found }
    # )
    endpoint = ->(c : Tjeneste::Middlewares::TimingMiddleware::Context){ HTTP::Response.not_found }
    mid = Tjeneste::Middlewares::TimingMiddleware(Tjeneste::HttpContext).new(endpoint)

    req = HTTP::Request.new("GET", "/")

    assert mid.call(Tjeneste::HttpContext.new(req)).status_code == 404
  end

  it "fires a global timing event" do
    endpoint = ->(c : Tjeneste::Middlewares::TimingMiddleware::Context){ HTTP::Response.not_found }
    mid = Tjeneste::Middlewares::TimingMiddleware(Tjeneste::HttpContext).new(endpoint)

    req = HTTP::Request.new("GET", "/")

    subscriber_notified = false

    Tjeneste::EventSystem::Global.subscribe(Tjeneste::Middlewares::TimingMiddleware, "timing") do |timing, req|
      subscriber_notified = true
    end

    mid.call(Tjeneste::HttpContext.new(req))

    assert subscriber_notified
  end
end
