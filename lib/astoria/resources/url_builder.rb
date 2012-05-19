require 'addressable/template'
require 'addressable/uri'

module Astoria
  class UrlBuilder
    def initialize(base, options = {})
      @base = if base.is_a?(Addressable::URI)
        base
      else
        uri = Addressable::URI.parse(base.sub(/\/$/, ''))
        uri.query = options[:query] if options[:query]
        uri
      end
      @template = Addressable::Template.new(@base)
      @root = options.fetch(:root, '')
    end

    def root_path
      @root
    end

    def build(mapping = {})
      @template.expand(mapping.stringify_keys).to_str
    end

    def root
      uri = @base.dup
      uri.path = root_path
      self.class.new(uri, root: root_path)
    end

    def path(path)
      path.split('/').inject(self) { |m, segment| m.segment(segment) }
    end

    def segment(segment)
      uri = @base.dup
      uri.path = [uri.path, segment].join('/') if segment.present?
      self.class.new(uri, root: root_path)
    end

    def param(key)
      uri = @base.dup
      uri.query_values = (uri.query_values || {}).merge(key => "{#{key}}")
      uri.query = uri.query.gsub('%7B', '{').gsub('%7D', '}')
      self.class.new(uri, root: root_path)
    end
  end
end
