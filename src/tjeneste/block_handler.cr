module Tjeneste
  class BlockHandler
    include HTTP::Handler

    def initialize(&@block : HTTP::Server::Context -> Nil)
    end

    def call(context : HTTP::Server::Context)
      @block.call(context)
    end
  end
end
