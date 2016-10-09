require "./node"

module Tjeneste
  module Routing
    class Route
      getter path : Array(Node)
      getter action : Action | HTTP::Handler

      def initialize(@path, @action)
      end
    end
  end
end
