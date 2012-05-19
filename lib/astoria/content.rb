module Astoria
  class Content
    attr_reader :url_builder, :links

    def initialize(url_builder = nil, params = {})
      @url_builder = url_builder
      if url_builder
        @links = {}
        @links[:self] = url_builder.build(params)
      end
    end

    def to_hash
      url_builder ? {_links: links} : {}
    end
  end
end

