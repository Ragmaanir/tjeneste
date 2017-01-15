require "http"

EmptyBlock = ->(ctx : HTTP::Server::Context) { nil }

enum Verb
  GET    = 1
  POST   = 2
  PUT    = 3
  PATCH  = 4
  DELETE = 5
  HEAD   = 6
end

class Node
  property parent : Node?
  getter children : Array(Node)
  getter name : String?

  def initialize(@name : String? = nil, @children = [] of Node)
  end

  def root?
    parent == nil
  end

  def depth : Int
    node = parent
    i = 0
    while node
      i += 1
      node = node.parent
    end

    i
  end

  def ==(other : Node)
    matchers == other.matchers
  end

  def stringify : String
    # val = {:name => @name} of Symbol => String?

    # if !children.empty?
    #   val = val.merge({:children => children.map(&.stringify.as(String)).join(",")})
    # end

    # "Node(#{val})"

    cs = "[" + children.map(&.stringify.as(String)).join(",") + "]"
    "Node(name: #{@name}, children: #{cs})"

    # {"name" => @name, "children" => @children.map(&.stringify.as(Hash))}
  end
end

class RouterBuilder
  macro build(&block)
    b = RouterBuilder.new
    b.build_block {{block}}
    #Router.new(b.root)
    b.root
  end

  def initialize
    @root = Node.new
    @node_stack = [@root] of Node
  end

  getter root : Node
  getter node_stack : Array(Node)

  def current_node
    @node_stack.last
  end

  def build_block(&block)
    with self yield
  end

  def append_child(node : Node)
    node.parent = current_node
    current_node.children << node
  end

  {% for verb in Verb.constants %}
    {%
      v = verb.downcase
      code = "
    macro #{v.id}(name)
      name = {{name}}

      append_child(Node.new({{name}}))
    end
    "
    %}
    {{code.id}}
  {% end %}

  macro path(name, &block)
    %node = Node.new({{name}})
    puts "NEW: #{%node.inspect}"
    node_stack << %node
    puts "STACK: \n#{node_stack.map(&.inspect).join("\n")}\n---"

    build_block {{block}}

    node_stack.pop
    append_child(%node)
  end
end

routes = RouterBuilder.build do
  path("topics") do
    get "123"
    path(":id") do
      get "comments"
    end
  end
end

p routes.stringify
