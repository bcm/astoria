require 'mime/types'

module Astoria
  class EntityProvider
    include Astoria::Logging

    class << self; attr_accessor :type, :media_type; end

    cattr_reader :providers, instance_writer: false
    @@providers = []

    def supports?(media_type)
      self.class.media_type == MediaTypes::ANYTHING ||
        self.class.media_type == media_type ||
          (self.class.media_type.raw_media_type == media_type.raw_media_type &&
           self.class.media_type.raw_subtype == '*')
    end

    def writeable?(type, media_type)
      # subclasses must implement. be careful to respect media type's charset.
      raise UnimplementedError
    end

    def write(obj, media_type, out)
      # subclasses must implement. be careful to respect media type's charset.
      raise UnimplementedError
    end

    def distance_in_ancestry(type, distance = 0)
      return distance if self.class.type == type || !self.class.type.in?(type.ancestors - type.included_modules)
      distance_in_ancestry(type.superclass, distance+1)
    end

    def self.register(klass)
      providers << klass.new
    end

    def self.find_best_match(type, media_type)
      candidates = providers.find_all { |p| p.supports?(media_type) }
      # XXX: sort media types by x/y < x/* < */*, ie more specific is better
      # nearer ancestors are preferable to more distant ones
      candidates.sort_by! { |p| [p.class.media_type.to_s.downcase, p.distance_in_ancestry(type) ] }
      candidates.detect { |p| p.writeable?(type, media_type) }
    end
  end
end

require 'astoria/providers/json_provider'
require 'astoria/providers/plaintext_provider'
