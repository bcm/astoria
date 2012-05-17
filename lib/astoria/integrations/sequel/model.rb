require 'active_support/concern'
require 'astoria/logging'

module Astoria
  module Integrations
    module Sequel
      module Model
        extend ActiveSupport::Concern
        include Astoria::Logging

        module AttributeNarrowing
          # Narrows the attributes selected based on the provided options.
          #
          # @param [Hash] options
          # @option options [Array] :attr (all) - the list of attributes to select
          # @return [Sequel::Dataset] - the narrowed dataset
          def narrow_attributes(options = {})
            if options[:attr]
              select(*(options[:attr]))
            else
              self
            end
          end
        end

        module Pagination
          # Paginates the dataset based on the provided options.
          #
          # @param [Hash] options
          # @option options [Integer] :page (1)
          # @option options [Integer] :per (25)
          # @return [Sequel::Dataset] - the paginated dataset
          def paginate(options = {})
            page = options[:page].to_i
            page = 1 unless page > 0
            per = options[:per].to_i
            per = 25 unless per > 0
            super(page, per)
          end
        end

        included do
          dataset_module AttributeNarrowing
          dataset_module Pagination
        end
      end
    end
  end
end
