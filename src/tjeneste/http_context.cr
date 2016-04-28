require "http"

module Tjeneste
  class HttpContext

    getter context : HTTP::Server::Context

    def initialize(@context : HTTP::Server::Context)
    end

    def request
      context.request
    end

    def response
      context.response
    end
  end
end
