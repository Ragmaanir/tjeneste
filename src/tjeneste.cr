require "logger"
require "colorize"
require "kontrakt"
require "besked"

require "./tjeneste/**"

module Tjeneste
  alias HttpBlock = (HTTP::Server::Context -> Nil)

  # module RB
  #   macro path(name)
  #     Routing::InnerNode.new
  #     Routing::PathMatcher.new(name)
  #   end
  # end
end
