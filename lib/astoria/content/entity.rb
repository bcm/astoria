module Astoria
  class Entity < Content
    attr_reader :value

    def initialize(value, url_builder, options = {})
      super(url_builder, options.merge(self_params: {id: value.id}))
      @value = value
    end

    def to_hash
      data = if value.respond_to?(:to_hash)
        value.to_hash
      elsif value.respond_to?(:values)
        value.values
      else
        value
      end
      data = data.keep_if { |key, value| key.in?(query_params[:attr]) } if query_params.key?(:attr)
      super.merge(data)
    end
  end
end
