module Tjeneste
  module Routing
    class Node
      property :parent
      getter :children, :matchers, :action

      def initialize(
        @matchers = [] of Matcher,
        @children = [] of Node,
        @action = nil : (HttpContext -> Nil)?)
        @children.each{ |c| c.parent = self }
      end

      def root?
        parent == nil
      end

      def leaf?
        children.empty?
      end

      def match(request : RequestState) : RequestState?
        results = [] of MatchResult

        all_match = matchers.all? do |m|
          res = m.match(request)
          results << res
          case res
            when MatchSuccess then request = res.request
          end
        end

        request if all_match
      end

      def to_s
       "Node(matchers: #{matchers}, children: [#{children.map{ |c| c.to_s as String }.join(",")}])"
      end

      def ==(other : Node)
        matchers == other.matchers && children == other.children
      end
    end
  end
end
