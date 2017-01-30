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
          indentation = "  "*node.depth

          case node
          when InnerNode
            constraints = stringify_constraints(node.constraints)
            constraints = " #{constraints}" if constraints.size > 0
            output << "#{indentation}InnerNode:#{constraints}"
          when TerminalNode
            constraints = stringify_constraints(node.constraints)
            constraints = " #{constraints}" if constraints.size > 0
            output << "#{indentation}TerminalNode:#{constraints}"
          else raise "not handled"
          end
        end

        output.join("\n")
      end

      private def stringify_constraints(constraints : Array(RoutingConstraint)) : String
        constraints.map do |m|
          case m
          when PathConstraint        then m.matcher.inspect
          when BindingPathConstraint then %[{"#{m.name}" => /#{m.regex.source}/}]
          when HttpMethodConstraint  then m.verb
          else                            raise "unhandled constraint: #{m}"
          end
        end.join(" ")
      end
    end
  end
end
