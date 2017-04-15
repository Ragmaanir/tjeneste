module X(A)
  getter a : A

  def initialize(@a : A)
  end

  macro included
    def self.call(ctx : A)
      new(ctx).call_wrapper
    end

    def call_wrapper
      #{{@type.name.id}}::Params.new
      Params.new
    end
  end

  module Params(A)
    def t
      A
    end
  end
end

class C
  include X(Int32)

  class Params
    include X::Params(Int32)
  end

  def call
  end
end

class D
  include X(String)

  class Params
    include X::Params(String)
  end

  def call
  end
end

puts C.call(1)

puts D.call("test")

puts C::Params.new.t
