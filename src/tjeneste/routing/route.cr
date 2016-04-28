require "./node"

module Tjeneste
  module Routing
    class Route
      getter path   : Array(Node)
      getter action : Action

      def initialize(@path : Array(Node), @action : Action)
      end

    end
  end
end
