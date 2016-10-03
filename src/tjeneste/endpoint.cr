module Tjeneste
  module Endpoint
    # def call_wrapper(request : HTTP::Request) # FIXME find better name
    #   params = Params.new(request.query_params.to_h)
    #   data = Data.from_json(request.body)
    #   call(params, data)
    # end

    macro included
      def call_wrapper(request : HTTP::Request) # FIXME find better name
        params = Params.new(request.query_params.to_h)
        data = Data.from_json(request.body.to_s)
        call(params, data)
      end
    end

    module Params
      # include MappingDSL
      # include ValidationDSL

      macro mapping(hash)
        #JSON.mapping({{hash}})
        def initialize(input)

        end
      end

      macro validation(&block)
      end
    end

    module Data
      macro mapping(hash)
        JSON.mapping({{hash}})
      end

      macro validation(&block)
      end
    end
  end
end

class Example
  include Tjeneste::Endpoint

  class Params
    include Tjeneste::Endpoint::Params

    mapping({
      id:   Int32,
      name: String,
    })

    validation do
      id { id.present? && id > 0 }
      name { name.present? && name.size > 3 }
    end
  end

  class Data
    include Tjeneste::Endpoint::Data

    mapping({
      id:   Int32,
      name: String,
    })

    validation do
      id { present? && id > 0 }
      name { present? && name.size > 3 }
    end
  end

  def call(params : Params, data : Data)
    p data
  end
end

r = HTTP::Request.new("GET", "/", nil, %({"id" : 1, "name" : "test"}))
x = Example.new
x.call_wrapper(r)
