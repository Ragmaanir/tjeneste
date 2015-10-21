
class Base
end

class Gen(T)
end

macro ident(x)
  {{x}}
end

macro xxx(cls)
  CONST = ident(Base)
  {{cls}}(CONST)
end

xxx(Gen)

# ERROR: invalid constant value
