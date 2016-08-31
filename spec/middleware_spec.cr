# require "./spec_helper"

# describe Tjeneste::Middleware do
#   test "responds with 404 when no middleware is chained" do
#     # mid = Tjeneste::TimingMiddleware(Tjeneste::TimingMiddleware::Context -> HTTP::Response).new(
#     #   ->(c : Tjeneste::TimingMiddleware::Context){ HTTP::Response.not_found }
#     # )
#     endpoint = ->(c : Tjeneste::Middlewares::TimingMiddleware::Context) do
#       c.response.status_code = 404
#     end
#     mid = Tjeneste::Middlewares::TimingMiddleware(Tjeneste::HttpContext).new(endpoint)

#     req = HTTP::Request.new("GET", "/")
#     ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(MemoryIO.new("")))

#     mid.call(Tjeneste::HttpContext.new(ctx))
#     assert ctx.response.status_code == 404
#   end

#   test "fires a global timing event" do
#     endpoint = ->(c : Tjeneste::Middlewares::TimingMiddleware::Context) do
#       c.response.status_code = 404
#     end
#     mid = Tjeneste::Middlewares::TimingMiddleware(Tjeneste::HttpContext).new(endpoint)

#     req = HTTP::Request.new("GET", "/")
#     ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(MemoryIO.new("")))

#     subscriber_notified = false

#     Tjeneste::EventSystem::Global.subscribe(Tjeneste::Middlewares::TimingMiddleware, "timing") do |timing, req|
#       subscriber_notified = true
#     end

#     mid.call(Tjeneste::HttpContext.new(ctx))

#     assert subscriber_notified
#   end
# end
