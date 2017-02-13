require "logger"
require "colorize"
require "kontrakt"
require "besked"

require "./tjeneste/**"

module Tjeneste
  alias HttpBlock = (HTTP::Server::Context -> Nil)

  EmptyBlock = ->(ctx : HTTP::Server::Context) { nil }
end
