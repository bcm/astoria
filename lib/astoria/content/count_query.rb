module Astoria
  module Content
    class CountQuery
      attr_reader :links, :count

      def initialize(count, url_builder)
        @count = count
        @links = {}
        @links[:self] = url_builder.build
      end

      def to_serializable_hash
        data = {}
        data[:_links] = links
        data[:count] = count
        data
      end
    end
  end
end
