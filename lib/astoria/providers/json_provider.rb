require 'yajl'

module Astoria
  module MediaTypes
    JSON = find('application/json')
  end

  class JsonProvider < EntityProvider
    self.type = Object
    self.media_type = MediaTypes::JSON

    def writeable?(type, media_type)
      type.method_defined?(:to_hash)
    end

    def write(obj, media_type, out)
      raise "Invalid encoding #{encoding} specified for JSON serialization" unless media_type.utf8?
      # assumes obj.to_hash returns data in UTF-8
      Yajl::Encoder.encode(obj.to_hash) { |chunk| out.write(chunk) }
    end
  end
end

Astoria::EntityProvider.register Astoria::JsonProvider
