require 'mime/types'

module Astoria
  module MediaTypes
    PLAINTEXT = find('text/plain')
  end

  class PlaintextProvider < EntityProvider
    self.type = Object
    self.media_type = MediaTypes::PLAINTEXT

    def writeable?(type, media_type)
      type.method_defined?(:to_s)
    end

    def write(obj, media_type, out)
      out.write(obj.to_s.encode(media_type.encoding))
    end
  end
end

Astoria::EntityProvider.register Astoria::PlaintextProvider
