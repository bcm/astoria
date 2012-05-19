require 'mime/types'

module Astoria
  class MediaType < SimpleDelegator
    attr_reader :params

    def initialize(type, params = {})
      super(MediaTypes.find(type))
      @params = params
    end

    def charset
      params[:charset]
    end

    def encoding
      Encoding.find(charset)
    end

    def utf8?
      encoding == Encoding.find("UTF-8")
    end

    def self.create(str)
      type, p = str.split(';')
      params = HashWithIndifferentAccess[p.strip.split(',').map { |pair| pair.strip.split('=') }]
      new(type.strip, params)
    end
  end

  module MediaTypes
    ANYTHING = '*/*'

    def self.find(str)
      MIME::Types[str].first
    end
  end
end
