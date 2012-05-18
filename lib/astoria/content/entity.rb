module Astoria
  class Entity < Content
    attr_reader :value

    def initialize(value, url_builder, options = {})
      super(url_builder, {id: value.id})
      @value = value
    end

    def to_serializable_hash
      data = if value.respond_to?(:to_serializable_hash)
        value.to_serializable_hash
      elsif value.respond_to?(:values)
        value.values
      else
        value
      end
      super.merge(data)
    end
  end
end
