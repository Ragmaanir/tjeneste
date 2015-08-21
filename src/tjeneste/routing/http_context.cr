module Tjeneste
  module Routing
    class HttpContext
      def initialize(@request : HTTP::Request)
      end
    end
  end
end
