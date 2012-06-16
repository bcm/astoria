module Astoria
  class Content
    include Astoria::Logging

    attr_reader :url_builder, :query_params, :mapping, :links

    def initialize(url_builder = nil, options = {})
      @url_builder = url_builder
      @query_params = options.fetch(:query_params, {})
      @mapping = options.fetch(:mapping, {})
      @links = []
    end

    def add_link(href, rel, options = {})
      @links << Link.new(href, rel, options)
    end

    def add_self_relative_link(rel, options = {})
      add_relative_link(url_builder, rel, options)
    end

    def add_root_relative_link(rel, options = {})
      add_relative_link(root_url_builder, rel, options)
    end

    def add_relative_link(builder, rel, options = {})
      options = options.dup
      path = options.delete(:path)
      builder = builder.path(path) if path.present?
      add_link(builder.build(mapping.merge(options)), rel, options)
    end

    def root_url_builder
      url_builder.root if url_builder
    end

    def to_hash(options = {})
      data = {}
      links_by_rel = links.group_by(&:rel)
      if links_by_rel.any?
        rel_whitelist = Array.wrap(options.fetch(:links, {}).fetch(:rels, []))
        data[:_links] = links_by_rel.each_with_object({}) do |(rel, ls), m|
          if rel_whitelist.empty? || rel.in?(rel_whitelist)
            if ls.count > 1
              m[rel] = ls.map { |l| l.to_s }
            elsif ls.any?
              m[rel] = ls.first.to_s
            end
          end
        end
      end
      data
    end
  end

  class Link
    attr_reader :href, :rel, :type, :title

    def initialize(href, rel, options = {})
      @href = href
      @rel = rel
      @type = options[:type]
      @title = options[:title]
    end

    def to_s
      out = []
      out << [:href, href]
      [:type, :title].each do |name|
        val = send(name)
        out << [name, val] if val.present?
      end
      out.each_with_object({}) { |pair, m| m[pair.first] = pair.last }
    end
  end
end

