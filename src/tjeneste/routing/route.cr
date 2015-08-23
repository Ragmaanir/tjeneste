module Tjeneste
  module Routing
    class Route
      getter :path, :action

      def initialize(@path : Array(Node), @action : Action)
      end

    end
  end
end
