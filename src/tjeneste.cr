require "logger"
require "colorize"
require "kontrakt"
require "besked"

class Class
  def <=(other : T.class) forall T
    {{@type <= T}}
  end
end

require "./tjeneste/**"

module Tjeneste
  alias HttpBlock = (HTTP::Server::Context -> Nil)

  EmptyBlock = ->(ctx : HTTP::Server::Context) { nil }
end
