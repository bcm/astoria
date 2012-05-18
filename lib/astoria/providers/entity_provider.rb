require 'mime/types'

module Astoria
  module MimeTypes
    ANYTHING = '*/*'
  end

  def self.EntityProvider(type, media_type = MimeTypes::ANYTHING)
    c = Class.new(EntityProvider)
    c.type = type
    c.media_type = media_type
    c
  end

  class EntityProvider
    include Astoria::Logging

    cattr_accessor :type, :media_type, instance_writer: false

    cattr_reader :providers, instance_writer: false
    @@providers = []

    def supports?(media_type)
      self.media_type == MimeTypes::ANYTHING ||
        self.media_type == media_type ||
          (self.media_type.raw_media_type == media_type.raw_media_type && self.media_type.raw_subtype == '*')
    end

    def writeable?(type, media_type)
      self.media_type == media_type
    end

    def write(obj, media_type, out)
      # subclasses must implement. be careful to respect media type's charset.
      raise UnimplementedError
    end

    def distance_in_ancestry(type, distance = 0)
      return distance if self.type == type || !self.type.in?(type.ancestors - type.included_modules)
      distance_in_ancestry(type.superclass, distance+1)
    end

    def self.register(klass)
      providers << klass.new
    end

    def self.find_best_match(type, media_type)
      providers.
        find_all { |p| p.supports?(media_type) }.
        # XXX: sort media types by x/y < x/* < */*, ie more specific is better
        # nearer ancestors are preferable to more distant ones
        sort_by { |p| [p.media_type.to_s.downcase, p.distance_in_ancestry(type) ] }.
        detect { |p| p.writeable?(type, media_type) }
    end
  end
end

require 'astoria/providers/json_provider'
