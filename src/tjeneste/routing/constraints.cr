module Tjeneste
  module Routing
    enum Verb
      GET
      POST
      PUT
      PATCH
      DELETE
      HEAD
      REPORT
      TRACE
      CONNECT
      OPTIONS
    end

    abstract class RoutingConstraint
      abstract def match(request : RoutingState) : MatchResult
      abstract def ==(other : RoutingConstraint)

      private def match_success(request : RoutingState)
        MatchSuccess.new(RoutingState.new(request, request.path_index + 1))
      end

      private def match_failure(left : String, right : String)
        MatchFailure.new("#{left} != #{right}")
      end

      def short_name
        self.class.name.split("::").last # FIXME util
      end
    end

    class BindingPathConstraint < RoutingConstraint
      getter regex : Regex # TODO add closure
      getter name : String

      def initialize(@name : String, @regex : Regex)
      end

      def match(request : RoutingState) : MatchResult
        if request.remaining_segments? && (m = full_match(regex, request.current_segment))
          # match_success(request)
          MatchSuccess.new(RoutingState.new(request, request.path_index + 1, {name => m[0]}))
        else
          match_failure(regex.source, request.inspect)
        end
      end

      private def full_match(regex : Regex, segment : String) : Regex::MatchData?
        m = regex.match(segment)
        m if m && m[0] == segment
      end

      def source
        regex.source
      end

      def ==(other : self)
        name == other.name && regex == other.regex
      end

      def ==(other)
        false
      end

      def to_s(io : IO)
        io << "#{short_name}(#{name}: #{regex.source})"
      end
    end

    class PathConstraint < RoutingConstraint
      alias MatcherClasses = String | Regex

      getter matcher

      def initialize(@matcher : MatcherClasses)
      end

      def match(request : RoutingState)
        match_internally(@matcher, request)
      end

      private def match_internally(matcher : String, request : RoutingState) : MatchResult
        if request.remaining_segments? && request.current_segment == matcher
          match_success(request)
        else
          match_failure(matcher, request.inspect)
        end
      end

      private def match_internally(matcher : Regex, request : RoutingState) : MatchResult
        if request.remaining_segments? && (m = matcher.match(request.current_segment))
          match_success(request)
        else
          match_failure(matcher.source, request.inspect)
        end
      end

      def ==(other : self) : Bool
        @matcher == other.matcher
      end

      def ==(other)
        false
      end

      def to_s(io : IO)
        io << "#{short_name}(#{matcher.inspect})"
      end
    end

    class HttpMethodConstraint < RoutingConstraint
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

      def ==(other : self) : Bool
        @verb == other.verb
      end

      def ==(other)
        false
      end

      def to_s(io : IO)
        io << "#{short_name}(#{verb})"
      end
    end
  end
end
