module Tjeneste
  module Routing

    enum Verb
      GET     = 1
      POST    = 2
      PUT     = 3
      DELETE  = 4
      HEAD    = 5
    end

    abstract class Matcher
      abstract def match(request : RequestState) : RequestState?
      abstract def ==(other : Matcher)
    end

    class PathMatcher < Matcher

      PREDEFINED_MATCHERS = {
        int: /\A\d+/
      }

      getter :matcher

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

      def ==(other : PathMatcher) : Bool
        @matcher == other.matcher
      end

      def ==(other)
        false
      end
    end

    class VerbMatcher < Matcher
      getter :verb

      def initialize(@verb : Verb)
      end

      def match(request : RequestState)
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
    end

  end
end
