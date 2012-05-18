module Astoria
  class CountQuery < Content
    attr_reader :count

    def initialize(count, url_builder, options = {})
      super(url_builder)
      @count = count
    end

    def to_serializable_hash
      super.merge(count: count)
    end
  end
end
