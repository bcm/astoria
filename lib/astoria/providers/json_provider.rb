require 'yajl'

module Astoria
  module MediaTypes
    JSON = MediaType.create('application/json;charset=utf-8')
  end

  class JsonProvider < EntityProvider
    self.type = Object
    self.media_type = MediaTypes::JSON

    def writeable?(type, media_type)
      type.method_defined?(:to_hash)
    end

    def write(obj, media_type, out)
      unless media_type.respond_to?(:utf8?) && media_type.utf8?
        raise "Invalid encoding #{media_type.encoding} specified for JSON serialization"
      end
      # assumes obj.to_hash returns data in UTF-8
      Yajl::Encoder.encode(obj.to_hash) { |chunk| out.write(chunk) }
    end
  end
end

Astoria::EntityProvider.register Astoria::JsonProvider
