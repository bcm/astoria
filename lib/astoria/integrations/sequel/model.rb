require 'active_support/concern'

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
              to_include = options[:attr]
              to_include += options[:required] if options[:required]
              select(*to_include)
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
          class << self
            attr_accessor :column_mapping, :attribute_mapping, :required_columns
          end

          self.column_mapping = {}
          self.attribute_mapping = {}
          self.required_columns = []

          dataset_module AttributeNarrowing
          dataset_module Pagination
        end

        def mapped_attribute_hash(attrs)
          attrs.each_with_object({}) { |attr, m| m[attr] = send(self.class.mapped_attribute(attr)) }
        end

        def mapped_column_hash(cols)
          cols.each_with_object({}) { |col, m| m[self.class.mapped_column(col)] = send(col) }
        end

        module ClassMethods
          def map_columns(hash)
            self.column_mapping = hash
            self.attribute_mapping = hash.invert
          end

          def require_columns(*cols)
            self.required_columns = cols
          end

          def narrowing_options(options = {})
            options = options.dup
            attrs = options.delete(:attr)
            options[:attr] = mapped_attributes(attrs) if attrs
            options.merge(required: required_columns)
          end

          def mapped_attribute(attr)
            attribute_mapping.fetch(attr, attr)
          end

          def mapped_attributes(attrs)
            attrs.map { |attr| mapped_attribute(attr) }
          end

          def mapped_columns(cols)
            cols.map { |col| mapped_column(col) }
          end

          def mapped_column(col)
            column_mapping.fetch(col, col)
          end
        end
      end
    end
  end
end
