require "logger"
require "colorize"
require "kontrakt"
require "besked"

require "./tjeneste/**"

module Tjeneste
  alias HttpBlock = (HTTP::Server::Context -> Nil)

  EmptyBlock = ->(ctx : HTTP::Server::Context) { nil }

  # module RB
  #   macro path(name)
  #     Routing::InnerNode.new
  #     Routing::PathMatcher.new(name)
  #   end
  # end
end
