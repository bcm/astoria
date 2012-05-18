require 'astoria/content'
require 'astoria/providers/entity_provider'
require 'astoria/resources/oauth2'
require 'astoria/resources/url_builder'
require 'mime/types'

module Astoria
  module Resource
    extend ActiveSupport::Concern
    include Astoria::Logging
    include Astoria::Resources::OAuth2

    # Returns any grouped query ids that were provided in the named request parameter as a semicolon-delimited list
    # of integers.
    #
    # If any of the values in the list is not a positive integer, the request is halted with a 400 response.
    #
    # @param param_name the request parameter name
    # @return [Array]
    def grouped_query_ids(param_name)
      unless @grouped_query_ids
        @grouped_query_ids = params[param_name].split(';').each_with_object([]) do |v, m|
          begin
            m << Integer(v)
          rescue ArgumentError
            fail 400, {param_name => "Bad query id value #{v}"}
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

    # Delegates the request to another resource, rewriting the request +PATH_INFO+ so that the subresource only
    # sees the splatted part.
    #
    # In the following example, a request for +/foo/:id/bar/baz+ would be handled by +BarResource.baz+.
    #
    #     map('/foo') { run FooResource }
    #
    #     class FooResource
    #       get '/:id/bar/*' do
    #         subresource BarResource, prefix: "/#{params[:id]}"
    #       end
    #     end
    #
    #     class BarResource
    #       get '/:id/baz' do
    #         "baz! #params[:id]"
    #       end
    #     end
    #
    # @param [Class] subresource_class
    # @param [Hash] options
    # @option options [String] :prefix ('/') a string to prepend to the splatted path
    def subresource(subresource_class, options = {})
      prefix = options.fetch(:prefix, '/')
      splat = params[:splat].first ? "/#{params[:splat].first}" : ''
      path_info = "#{prefix}#{splat}"
      script_name = request.script_name + request.path_info.sub(/#{splat}$/, '')
      subresource_env = env.merge('PATH_INFO' => path_info, 'SCRIPT_NAME' => script_name)
      subresource_class.call(subresource_env)
    end

    def url_builder
      @url_builder ||= UrlBuilder.new(self.url)
    end

    def count_query(count, options = {})
      set_resource(Astoria::CountQuery.new(count, url_builder, options))
    end

    def entity(ent, options = {})
      set_resource(Astoria::Entity.new(ent, url_builder, options))
    end

    def grouped_query(ids, group, options = {})
      set_resource(Astoria::GroupedQuery.new(ids, group, url_builder, options))
    end

    def paged_query(paged_array, options = {})
      set_resource(Astoria::PagedQuery.new(paged_array, url_builder, options))
    end

    def set_resource(resource)
      env['astoria.resource'] = resource
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

    attr_reader :media_type

    def content_type(type = nil, params = {})
      ct = super
      @media_type = MIME::Types[ct].first if type
    end

    def write_body(resource)
      writer = EntityProvider.find_best_match(resource.class, media_type)
      unless writer
        mt = media_type
        content_type(:txt)
        halt 500, "No matching entity provider for resource of type #{resource.class} and media type #{mt}"
      end
      writer.write(resource, media_type, response)
    end

    def fail(code, errors)
      write_body(Astoria::Errors.new(errors))
      halt code
    end

    included do
      disable :show_exceptions
      disable :dump_errors

      use(Astoria::OAuth2::BearerTokenMiddleware)

      before do
        content_type(:json) # XXX: figure out what's acceptable to the request
        @t1 = Time.now
      end

      after do
        if @t1
          ms = (Time.now - @t1) * 1000
          logger.debug 'Compute response (%.1fms)' % [ms]
        end
        resource = env['astoria.resource']
        # XXX: if Rack::Response, use its status, headers, body
        if resource
          set_status(resource)
          write_body(resource)
        end
      end

      not_found do
        write_body(Astoria::Errors.new('Route not found')) unless body
      end

      error do
        error = env['sinatra.error'] || 'Unknown error'
        status(error.respond_to?(:status) ? error.status : 500)
        error.headers.each { |key, val| headers[key] = val } if error.respond_to?(:headers)
        write_body(error.respond_to?(:resource) ? error.resource : Astoria::Errors.new(error))
        dump_errors!(error) if status == 500
      end
    end
  end
end
