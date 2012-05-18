module Astoria
  autoload :CountQuery, 'astoria/content/count_query'
  autoload :Entity, 'astoria/content/entity'
  autoload :GroupedQuery, 'astoria/content/grouped_query'
  autoload :PagedQuery, 'astoria/content/paged_query'

  class Content
    attr_reader :links

    def initialize(url_builder, params = {})
      @links = {}
      @links[:self] = url_builder.build(params)
    end

    def to_serializable_hash
      {_links: links}
    end
  end
end

