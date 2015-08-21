module Tjeneste
  module Routing
    class Route
      getter :path, :action

      def initialize(@path : Array(Node), @action : (HttpContext -> Nil))
      end
    end
  end
end
