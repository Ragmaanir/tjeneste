require "microtest"

require "../src/tjeneste"

include Microtest::DSL

def send_request(http_handler, *args)
  req = HTTP::Request.new(*args)
  io = IO::Memory.new(1000)
  ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(io))

  http_handler.call(ctx)

  ctx.response.close
  io.rewind
  HTTP::Client::Response.from_io(io)
end

def lazy_request(method, url)
  req = HTTP::Request.new(method, url)
  resp = IO::Memory.new(64)
  ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(resp))
  {->{
    ctx.response.close
    resp.rewind
    HTTP::Client::Response.from_io(resp)
  }, ctx}
end

def route!(router, method, url)
  req = HTTP::Request.new(method, url)
  resp = IO::Memory.new(64)
  ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(resp))

  route = router.route(req).not_nil!

  route.call_action(ctx)
  ctx.response.close

  resp.rewind
  HTTP::Client::Response.from_io(resp)
end

Microtest.run!([
  Microtest::DescriptionReporter.new,
  Microtest::ErrorListReporter.new,
  Microtest::SlowTestsReporter.new,
  Microtest::SummaryReporter.new,
] of Microtest::Reporter)
