require 'active_support/benchmarkable'
require 'active_support/concern'
require 'astoria/resources/oauth2'
require 'astoria/resources/url_builder'
require 'yajl'

module Astoria
  module Resource
    include ActiveSupport::Benchmarkable
    extend ActiveSupport::Concern
    include Astoria::Logging
    include Astoria::Resources::OAuth2

    # Computes a resource and returns a response for the request.
    #
    # Meant to be used in the context of a Sinatra route handler, like so:
    #
    #     get '/foo' do
    #       respond { {bar: :baz} }
    #     end
    #
    # Expects the provided block to return either a two-element array containing a custom status and the resource,
    # or just the resource itself (if the default status for the request method should be used). The block should also
    # set any custom request headers via the Sinatra +headers+ method.
    #
    # If no +representation_+ option is specified, +:json+ is assumed, and the provided resource is serialized to JSON.
    #
    # @param [Hash] options
    # @option options [Symbol] :representation (:json) the representation to be used for the computed response, as a
    #   Sinatra +mime_type+ value (eg :json, :html, :txt)
    # @return [Array] the response status and resource
    def respond(options = {}, &block)
      rv = benchmark("Respond", level: :debug, &block)
      (status, resource) = if rv.is_a?(Array)
        rv.slice(0, 2)
      else
        [nil, rv]
      end
      status = options[:status] || (if request.get? || request.head?
        resource.nil?? 404 : 200
      elsif request.put?
        201
      elsif request.delete?
        204
      else
        405
      end)
      status(status)
      set_resource(resource, options)
    end

    def set_resource(resource, options = {})
      representation = options.fetch(:representation, :json)
      content_type(representation)
      if resource
        content = if representation == :json
          if resource.respond_to?(:to_serializable_hash)
            Yajl::Encoder.encode(resource.to_serializable_hash)
          else
            Yajl::Encoder.encode(resource)
          end
        elsif representation == :txt
          resource.to_s
        else
          raise "Unsupported representation #{representation}"
        end
        body(content)
      end
    end

    # Returns a resource providing a consistent structure for error information.
    #
    # @param [Object] errors an object describing the error condition(s)
    # @return [Hash]
    def errors_resource(errors)
      {errors: errors}
    end

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
            status(400)
            set_resource(errors_resource({param_name => "Bad query id value #{v}"}))
            halt
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
    #         delegate_to_subresource BarResource, prefix: "/#{params[:id]}"
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
    def delegate_to_subresource(subresource_class, options = {})
      prefix = options.fetch(:prefix, '/')
      splat = params[:splat].first ? "/#{params[:splat].first}" : ''
      path_info = "#{prefix}#{splat}"
      script_name = request.script_name + request.path_info.sub(/#{splat}$/, '')
      subresource_env = env.merge('PATH_INFO' => path_info, 'SCRIPT_NAME' => script_name)
      subresource_class.call(subresource_env)
    end

    def url_builder
      UrlBuilder.new(self.url)
    end

    included do
      disable :show_exceptions
      disable :dump_errors

      use(Astoria::OAuth2::BearerTokenMiddleware)

      not_found do
        status(404)
        set_resource(errors_resource('Route not found'))
        halt(response.finish)
      end

      error do
        error = env['sinatra.error'] || 'Unknown error'
        status(error.respond_to?(:status) ? error.status : 500)
        error.headers.each { |key, val| headers[key] = val } if error.respond_to?(:headers)
        set_resource(error.respond_to?(:resource) ? error.resource : errors_resource(error))
        dump_errors!(error) if status == 500
        halt(response.finish)
      end
    end
  end
end
