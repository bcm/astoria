require 'mime/types'
require 'yajl'

module Astoria
  module MediaTypes
    JSON = MIME::Types['application/json'].first
  end

  class JsonProvider < EntityProvider(Object, MediaTypes::JSON)
    def write(obj, media_type, out)
      # assumes the resource data is in UTF-8
      data = obj.respond_to?(:to_serializable_hash) ? obj.to_serializable_hash : obj
      Yajl::Encoder.encode(data) { |chunk| out.write(chunk) }
    end
  end
end

Astoria::EntityProvider.register Astoria::JsonProvider
