# module Tjeneste
#   module Routing
#     # Actually builds just the array of children and returns them as :result
#     class NodeBuilder
#       getter result : Array(Node)

#       # def self.build(block : NodeBuilder -> Nil)
#       #   new(&block).result
#       # end

#       def initialize # (&block : NodeBuilder -> Nil)
#         @result = [] of Node
#       end

#       def build(&block)
#         with self yield
#         result
#       end

#       macro path(name, &block)
#         children = NodeBuilder.new.build {{block}}

#         result << InnerNode.new(
#           matchers: [PathMatcher.new("{{name.id}}/")] of Matcher,
#           children: children
#         )
#         nil
#       end

#       # def path(name, &block : NodeBuilder -> Nil) : Nil
#       #   children = NodeBuilder.build(&block)

#       #   @result << InnerNode.new(
#       #     matchers: [PathMatcher.new("#{name}/")] of Matcher,
#       #     children: children
#       #   )
#       #   nil
#       # end

#       # {% for verb in Verb.constants %}
#       #   def {{verb.id.downcase}}(*args) : Nil
#       #     action(Verb::{{verb.id}}, *args)
#       #   end

#       #   def {{verb.id.downcase}}(*args, &block : HTTP::Server::Context -> Nil) : Nil
#       #     action(Verb::{{verb.id}}, *args, &block)
#       #   end
#       # {% end %}

#       {% for verb in Verb.constants %}
#         {%
#           x = "
#         macro #{verb.id.downcase}(name, target)
#           action(Verb::#{verb.id}, {{name}}, {{target}})
#         end

#         macro #{verb.id.downcase}(*args, &block)
#           action(Verb::#{verb.id}, {{*args}}) {{block}}
#         end
#         "
#         %}
#         {{x.id}}
#       {% end %}

#       private def action(verb : Verb, name, target : HTTP::Handler | Action, *args) : Nil
#         @result << TerminalNode.new(
#           matchers: [PathMatcher.new(name), VerbMatcher.new(verb)] of Matcher,
#           action: target
#         )
#       end

#       private def action(verb : Verb, name, &block : HTTP::Server::Context -> Nil) : Nil
#         @result << TerminalNode.new(
#           matchers: [PathMatcher.new(name), VerbMatcher.new(verb)] of Matcher,
#           action: BlockHandler.new(&block)
#         )
#       end

#       def mount(name, middleware, *args) : Nil
#         # wrapper = ->(ctx : HTTP::Server::Context) { middleware.new(*args).call(ctx); nil }
#         @result << TerminalNode.new(
#           matchers: [PathMatcher.new(name)] of Matcher,
#           action: BlockHandler.new { |ctx| middleware.new(*args).call(ctx); nil }
#         )
#         nil
#       end
#     end
#   end
# end
