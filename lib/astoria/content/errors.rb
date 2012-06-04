module Astoria
  class Errors < Content
    attr_reader :errors

    def initialize(errors)
      super(nil)
      @errors = if errors.is_a?(Exception)
        if Astoria.env.development?
          errors.message
        else
          "An unknown error occurred"
        end
      else
        errors
      end
    end

    def to_hash
      super.merge(errors: errors)
    end
  end
end
