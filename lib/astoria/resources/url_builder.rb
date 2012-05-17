require 'addressable/template'
require 'addressable/uri'

module Astoria
  class UrlBuilder
    def initialize(base)
      @base = if base.is_a?(Addressable::URI)
        base
      else
        Addressable::URI.parse(base.sub(/\/$/, ''))
      end
      @template = Addressable::Template.new(@base)
    end

    def build(mapping = {})
      @template.expand(mapping.stringify_keys).to_str
    end

    def path(path)
      path.split('/').inject(self) { |m, segment| m.segment(segment) }
    end

    def segment(segment)
      uri = @base.dup
      uri.path = [uri.path, segment].join('/') if segment.present?
      self.class.new(uri)
    end

    def param(key)
      uri = @base.dup
      uri.query_values = (uri.query_values || {}).merge(key => "{#{key}}")
      uri.query = uri.query.gsub('%7B', '{').gsub('%7D', '}')
      self.class.new(uri)
    end
  end
end
