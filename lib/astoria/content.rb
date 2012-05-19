module Astoria
  class Content
    include Astoria::Logging

    attr_reader :url_builder, :query_params, :mapping, :links

    def initialize(url_builder = nil, options = {})
      @url_builder = url_builder
      @query_params = options.fetch(:query_params, {})
      @mapping = options.fetch(:mapping, {})
      @links = {self: url_builder.build(mapping)} if url_builder
    end

    def root_url_builder
      url_builder.root if url_builder
    end

    def to_hash
      url_builder ? {_links: links} : {}
    end
  end
end

