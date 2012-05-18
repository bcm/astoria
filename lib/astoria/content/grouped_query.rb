module Astoria
  # Encapsulates the results of a grouped query. Represents the results as a map from entity id to corresponding query
  # result.
  class GroupedQuery < Content
    attr_reader :group

    # @param [Array] ids the entity ids
    # @param [Hash] group the grouped query results
    # @param [Hash] options
    # @option options [Object] :default (+nil+) the default value to use if there is not a query result for a a given
    #   entity id
    def initialize(ids, group, url_builder, options = {})
      super(url_builder)
      default_value = options[:default]
      defaults = ids.each_with_object({}) {|id, m| m[id] = default_value}
      @group = defaults.merge(group)
    end

    def to_serializable_hash
      super.merge(group)
    end
  end
end
