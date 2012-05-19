require 'active_support/benchmarkable'
require 'astoria/content'
require 'astoria/providers/entity_provider'
require 'astoria/resources/oauth2'
require 'astoria/resources/url_builder'
require 'mime/types'

module Astoria
  module Resource
    include ActiveSupport::Benchmarkable
    extend ActiveSupport::Concern
    include Astoria::Logging
    include Astoria::Resources::OAuth2

    # If any of the values in the list is not a positive integer, the request  with a 400 response.
    #
    # @param param_name the request parameter name
    # @return [Array]
    def grouped_query_ids(param_name)
      unless @grouped_query_ids
        @grouped_query_ids = params[param_name].split(';').each_with_object([]) do |v, m|
          begin
            m << Integer(v)
          rescue ArgumentError
            fail(400, {param_name => "Bad query id value #{v}"})
          end
        end
      end
      @grouped_query_ids
    end

    # Returns the paged query options that were provided as the +page+ and +per+ request parameters.
    #
    # @return [Hash]
    def pagination_params
      page = params[:page].to_i
      page = 1 unless page > 0
      per = params[:per].to_i
      per = 25 unless per > 0
      {page: page, per: per}
    end

    # Returns the attribute filters that were provided as the +attr[]+ request parameters, or +nil+ if no such
    # parameters were provided.
    #
    # @return [Array]
    def attribute_filtering_params
      params[:attr] ? params[:attr].map(&:to_sym) : nil
    end

    # Returns the options relevant to paged queries that were provided as request parameters.
    #
    # @see #pagination_params
    # @see #attribute_filtering_params
    # @return [Hash]
    def paged_query_params
      pq = pagination_params
      af = attribute_filtering_params
      pq[:attr] = af if af
      pq
    end

    # Returns the options relevant to individual entity get requests that were provided as request parameters.
    #
    # @see #attribute_filtering_params
    # @return [Hash]
    def entity_get_params
      eg = {}
      af = attribute_filtering_params
      eg[:attr] = af if af
      eg
    end

    def url_builder
      @url_builder ||= UrlBuilder.new(self.url)
    end

    def count_query(count, options = {})
      Astoria::CountQuery.new(count, url_builder, options)
    end

    def entity(ent, options = {})
      Astoria::Entity.new(ent, url_builder, options) if ent
    end

    def grouped_query(ids, group, options = {})
      Astoria::GroupedQuery.new(ids, group, url_builder, options)
    end

    def paged_query(paged_array, options = {})
      Astoria::PagedQuery.new(paged_array, url_builder, options)
    end

    def route_eval(&block)
      entity = benchmark 'Compute response', level: :debug, &block
      # XXX: if Rack::Response, use its status, headers, body
      content_type(:json) unless content_type
      set_status(entity)
      write_body(entity) if entity
      throw :halt, nil
    end

    attr_reader :media_type

    def content_type(type = nil, params = {})
      ct = super
      @media_type = MediaType.create(ct) if type
      ct
    end

    def set_status(resource)
      code = if request.get? || request.head?
        resource.nil?? 404 : 200
      elsif app.request.put?
        201
      elsif app.request.delete?
        204
      else
        405
      end
      status(code)
    end

    def write_body(entity)
      writer = EntityProvider.find_best_match(entity.class, media_type)
      unless writer
        mt = media_type
        content_type(:txt)
        fail(500, "No matching entity provider for entity of type #{entity.class} and media type #{mt}")
      end
      writer.write(entity, media_type, response)
    end

    def fail(code, errors = nil)
      env['astoria.error'] = errors if errors
      halt(code)
    end

    included do
      cattr_accessor :resource_parent, :resource_path, instance_writer: false

      disable :show_exceptions
      disable :dump_errors

      use(Astoria::OAuth2::BearerTokenMiddleware)

      not_found do
        error = env['astoria.error'] || 'Route not found'
        content_type(:json)
        error.headers.each { |key, val| headers[key] = val } if error.respond_to?(:headers)
        response.body = ''
        write_body(error.respond_to?(:resource) ? error.resource : Astoria::Errors.new(error))
      end

      error do
        error = env['sinatra.error'] || env['astoria.error'] || 'Unknown error'
        content_type(:json)
        status(error.respond_to?(:status) ? error.status : 500)
        error.headers.each { |key, val| headers[key] = val } if error.respond_to?(:headers)
        write_body(error.respond_to?(:resource) ? error.resource : Astoria::Errors.new(error))
        dump_errors!(error) if status == 500
      end
    end

    module ClassMethods
      def resource(path)
        self.resource_path = path
      end

      def subresource(path, &block)
        resource = yield
        resource.constantize unless resource.is_a?(Class)
        resource.resource_path = path
        resource.resource_parent = self
      end

      def ancestor_resource_path
        if resource_parent
          [resource_parent.ancestor_resource_path, resource_path].compact.join('/')
        else
          resource_path
        end
      end

      def root_relative_resource_path
        ancestor_resource_path
      end

      def route_matches
        []
      end
    end
  end
end
