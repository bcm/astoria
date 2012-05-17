module Astoria
  module Content
    class Entity
      attr_reader :links, :value

      def initialize(value, url_builder)
        @links = {}
        @links[:self] = url_builder.build(id: value.id)
        @value = value
      end

      def to_serializable_hash
        data = {}
        data[:_links] = links
        data.merge(if value.respond_to?(:to_serializable_hash)
          value.to_serializable_hash
        elsif value.respond_to?(:values)
          value.values
        else
          value
        end)
      end
    end
  end
end
