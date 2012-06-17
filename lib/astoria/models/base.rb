module Astoria
  module Model
    extend ActiveSupport::Concern

    def etag
      unless defined?(@etag)
        @etag = "#{etag_identifier}-#{etag_timestamp}" if etag_identifier.present? && etag_timestamp.present?
      end
      @etag
    end

    def etag_identifier
      id
    end

    def etag_timestamp
      created_at
    end
  end
end
