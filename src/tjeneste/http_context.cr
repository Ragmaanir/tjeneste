module Tjeneste
  class HttpContext
    getter :request

    def initialize(@request : HTTP::Request)
    end
  end
end
