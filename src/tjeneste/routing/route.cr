require "./node"

module Tjeneste
  module Routing
    class Route
      getter path : Array(Node)
      getter action : Action | HTTP::Handler | HttpBlock

      def initialize(@path, @action)
      end

      def url
        path.map do |node|
          matcher = node.matchers.find { |m| m.is_a?(PathMatcher) }
          case matcher
          when PathMatcher then matcher.matcher
          end
        end
      end
    end
  end
end
