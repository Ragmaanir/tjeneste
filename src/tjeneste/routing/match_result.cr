module Tjeneste
  module Routing
    abstract class MatchResult
      abstract def success? : Bool
    end

    class MatchSuccess < MatchResult
      property request

      def initialize(@request : RoutingState)
      end

      def success?
        true
      end
    end

    class MatchFailure < MatchResult
      property error

      def initialize(@error : String)
      end

      def success?
        false
      end
    end
  end
end
