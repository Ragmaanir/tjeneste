require "microtest"

require "../src/tjeneste"

include Microtest::DSL

def send_request(http_handler, *args)
  req = HTTP::Request.new(*args)
  io = IO::Memory.new(1000)
  ctx = HTTP::Server::Context.new(req, HTTP::Server::Response.new(io))

  http_handler.call(ctx)

  io.rewind
  HTTP::Client::Response.from_io(io)
end

Microtest.run!([
  Microtest::DescriptionReporter.new,
  Microtest::ErrorListReporter.new,
  Microtest::SlowTestsReporter.new,
  Microtest::SummaryReporter.new,
] of Microtest::Reporter)
