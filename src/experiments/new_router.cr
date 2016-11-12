class Router
  getter root_node : InnerNode

  def initialize(@root_node)
  end
end

class Node
  getter name : String

  def initialize(@name)
  end
end

class InnerNode < Node
  getter children : Array(Node)

  def initialize(name)
    super
    @children = [] of Node
  end

  def inspect(io : IO)
    c = children.map { |i| "#{i}" }
    io << "InnerNode(#{name.inspect}, #{children})"
  end
end

class TerminalNode < Node
  def inspect(io : IO)
    io << "TerminalNode(#{name.inspect})"
  end
end

class RouterBuilder
  macro build(&block)
    b = RouterBuilder.new
    b.build_block {{block}}
    Router.new(b.root)
  end

  def initialize
    @root = InnerNode.new("")
    @node_stack = [@root] of InnerNode
  end

  getter root : InnerNode
  getter node_stack : Array(InnerNode)

  def current_node
    @node_stack.last
  end

  def build_block(&block)
    with self yield
  end

  macro get(name)
    current_node.children << TerminalNode.new({{name}})
  end

  macro path(name, &block)
    node = InnerNode.new({{name}})
    node_stack << node
    build_block {{block}}
    node_stack.pop
    current_node.children << node
  end
end

b = RouterBuilder.build do
  get "status"
  path "topics" do
    get "/"
    get "/:id"
  end
end

p b.root_node
