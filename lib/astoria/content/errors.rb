module Astoria
  class Errors < Content
    attr_reader :errors

    def initialize(errors)
      super(nil)
      @errors = errors.is_a?(Exception) ? errors.message : errors
    end

    def to_hash
      super.merge(errors: errors)
    end
  end
end
