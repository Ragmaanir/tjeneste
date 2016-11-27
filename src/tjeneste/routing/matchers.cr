module Tjeneste
  module Routing
    enum Verb
      GET    = 1
      POST   = 2
      PUT    = 3
      DELETE = 4
      HEAD   = 5
    end

    abstract class Matcher
      abstract def match(request : RoutingState) : RoutingState?
      abstract def ==(other : Matcher)
    end

    class PathMatcher < Matcher
      PREDEFINED_MATCHERS = {
        int: /\A\d+\z/,
      }

      getter matcher

      def initialize(@matcher : String | Regex | Symbol)
      end

      def match(request : RoutingState)
        match_internally(@matcher, request)
      end

      private def match_internally(matcher : String, request : RoutingState) : MatchResult
        if matcher == "" && !request.remaining_segments?
          MatchSuccess.new(RoutingState.new(request, request.path_index))
        else
          if request.current_segment == matcher
            MatchSuccess.new(RoutingState.new(request, request.path_index + 1))
          else
            MatchFailure.new("#{matcher} != #{request.current_segment}")
          end
        end
      end

      private def match_internally(matcher : Regex, request : RoutingState) : MatchResult
        if m = matcher.match(request.current_segment)
          MatchSuccess.new(RoutingState.new(request, request.path_index + 1))
        else
          MatchFailure.new("#{matcher.source} != #{request.current_segment}")
        end
      end

      private def match_internally(matcher : Symbol, request : RoutingState) : MatchResult
        predef = PREDEFINED_MATCHERS[matcher]

        if m = predef.match(request.current_segment)
          MatchSuccess.new(RoutingState.new(request, request.path_index + 1))
        else
          MatchFailure.new("#{predef.source} != #{request.current_segment}")
        end
      end

      def ==(other : PathMatcher) : Bool
        @matcher == other.matcher
      end

      def ==(other)
        false
      end

      def to_s(io : IO)
        io << "PathMatcher(#{matcher.inspect})"
      end
    end

    class VerbMatcher < Matcher
      getter verb : Verb

      def initialize(@verb)
      end

      def match(request : RoutingState)
        if verb.to_s == request.request.method
          MatchSuccess.new(request)
        else
          MatchFailure.new("FAILURE: #{verb} != #{request.request.method}")
        end
      end

      def ==(other : VerbMatcher) : Bool
        @verb == other.verb
      end

      def ==(other)
        false
      end

      def to_s(io : IO)
        io << "VerbMatcher(#{verb})"
      end
    end
  end
end
