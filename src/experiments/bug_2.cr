
class Base
end

class Gen(T)
end

macro ident(x)
  {{x}}
end

macro xxx(cls)
  {{cls}}(ident(Base))
end

xxx(Gen)

# ERROR: Syntax error in expanded macro: xxx:1: expecting token 'CONST', not 'ident'

# Syntax error in macro used for generic type parameter
