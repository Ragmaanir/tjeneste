module Tjeneste
  module Routing
    class RouterPrinter
      getter router

      def self.print(router : Router)
        new(router).print
      end

      def initialize(@router : Router)
      end

      def print
        output = [] of String

        router.traverse_depth_first do |node|
          indentation = "  "*(node.depth-1)
          case node
          when InnerNode
            matchers = stringify_matchers(node.matchers)
            matchers = " #{matchers}" if matchers.size > 0
            output << "#{indentation}InnerNode:#{matchers}"
          when TerminalNode
            matchers = stringify_matchers(node.matchers)
            matchers = " #{matchers}" if matchers.size > 0
            output << "#{indentation}TerminalNode:#{matchers}"
          end
          nil
        end

        output.join("\n")
      end

      private def stringify_matchers(matchers : Array(Matcher)) : String
        matchers.map do |m|
          case m
          when PathMatcher then m.matcher
          when VerbMatcher then m.verb
          end
        end.join(" ")
      end
    end
  end
end
