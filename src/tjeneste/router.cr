module Tjeneste
  class Router

    enum Verb
      GET     = 1
      POST    = 2
      PUT     = 3
      DELETE  = 4
      HEAD    = 5
    end

    class RequestState
      property :request, :path_index

      def initialize(@request : HTTP::Request, @path_index = 0)
      end

      def initialize(request : RequestState, @path_index = 0)
        @request = request.request
      end

      def path
        request.path[path_index..-1]
      end
    end

    abstract class MatchResult
      abstract def success? : Bool
    end

    class MatchSuccess < MatchResult
      property :request

      def initialize(@request : RequestState)
      end

      def success?
        true
      end
    end

    class MatchFailure < MatchResult
      property :error

      def initialize(@error)
      end

      def success?
        false
      end
    end

    abstract class Matcher
      abstract def match(request : RequestState) : RequestState?
    end

    class PathMatcher < Matcher

      PREDEFINED_MATCHERS = {
        int: /\A\d+/
      }

      def initialize(@matcher)
      end

      def match(request : RequestState)
        case @matcher
          when String then match_internally(@matcher as String, request)
          when Regex then match_internally(@matcher as Regex, request)
          when Symbol then match_internally(@matcher as Symbol, request)
          else raise "Unhandled matcher type #{@matcher.class}"
        end
      end

      private def match_internally(matcher : String, request : RequestState) : MatchResult
        if request.path.starts_with?(matcher)
          MatchSuccess.new(RequestState.new(request, request.path_index + matcher.length))
        else
          MatchFailure.new("#{matcher} != #{request.path}")
        end
      end

      private def match_internally(matcher : Regex, request : RequestState) : MatchResult
        if m = matcher.match(request.path)
          MatchSuccess.new(RequestState.new(request, request.path_index + m.length))
        else
          MatchFailure.new("#{matcher.source} != #{request.path}")
        end
      end

      private def match_internally(matcher : Symbol, request : RequestState) : MatchResult
        predef = PREDEFINED_MATCHERS[matcher]
        if m = predef.match(request.path)
          MatchSuccess.new(RequestState.new(request, request.path_index + m.length))
        else
          MatchFailure.new("#{predef.source} != #{request.path}")
        end
      end
    end

    class VerbMatcher < Matcher
      property :verb

      def initialize(@verb : Verb)
      end

      def match(request : RequestState)
        if verb.to_s == request.request.method
          MatchSuccess.new(request)
        else
          MatchFailure.new("FAILURE: #{verb} != #{request.request.method}")
        end
      end
    end

    class Node
      property :parent, :children, :matchers

      def initialize(@matchers = [] of Matcher, @children = [] of Node)
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

      #def inspect
      #  "Node(children: #{children.map(&:inspect).join(",")}, segment: #{segment})"
      #end
    end

    class Route
      getter :path

      def initialize(@path : Array(Node))
      end
    end

    getter :root, :logger

    def initialize(@root, @logger = Logger.new(STDOUT) : Logger)
    end

    def route(request) : Route?
      node = root
      node_path = [node]
      req = RequestState.new(request)

      while !node.leaf?
        next_node = node.children.find do |c|
          if res = c.match(req)
            req = res
          end
        end

        if next_node
          node = next_node
          node_path << node
        else
          break
        end
      end

      Route.new(node_path) if node.leaf?
    end

  end
end
