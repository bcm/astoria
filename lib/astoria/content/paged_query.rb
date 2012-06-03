module Astoria
  class PagedQuery < Content
    attr_reader :total, :collection

    def initialize(paged_array, url_builder, options = {})
      super(url_builder)
      page_url_builder = url_builder.param(:page)
      add_link(page_url_builder.build(mapping.merge(page: paged_array.next_page)), :next) if paged_array.next_page
      add_link(page_url_builder.build(mapping.merge(page: paged_array.prev_page)), :prev) if paged_array.prev_page
      add_link(page_url_builder.build(mapping.merge(page: 1)), :first) unless paged_array.first_page?
      add_link(page_url_builder.build(mapping.merge(page: paged_array.page_count)), :last) unless paged_array.last_page?
      @total = paged_array.pagination_record_count
      options = options.dup
      klass = options.delete(:type) || Entity
      entity_url_builder = url_builder.path('{id}')
      @collection = paged_array.map { |value| klass.new(value, entity_url_builder, options.merge(mapping: mapping)) }
    end

    def to_hash
      super.merge(total: total, collection: collection.map {|value| value.to_hash(links: {rels: :self}) })
    end
  end
end
