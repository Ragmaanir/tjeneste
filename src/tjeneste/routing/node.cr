module Tjeneste
  module Routing
    abstract class Node
      property :parent
      getter :matchers

      def initialize(@matchers = [] of Matcher)
      end

      def root?
        parent == nil
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
        matchers == other.matchers
      end
    end

    class InnerNode < Node
      getter :children

      def initialize(
        @matchers = [] of Matcher,
        @children = [] of Node)
        @children.each{ |c| c.parent = self }
      end

      def ==(other : InnerNode)
        super && children == other.children
      end

      def ==(other : Node)
        false
      end
    end

    class TerminalNode < Node
      getter :action

      def initialize(
        @matchers = [] of Matcher,
        @action = ->(_ctx : HttpContext){ raise "Action missing" } : (HttpContext -> Nil))
      end

      def ==(other : TerminalNode)
        super && action == other.action
      end

      def ==(other : Node)
        false
      end
    end
  end
end
