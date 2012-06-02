require 'attr_optional'
require 'attr_required'
require 'rack/request'
require 'rack/response'
require 'rack/oauth2/server'

module Astoria
  module OAuth2
    mattr_accessor :realm
    @@realm = 'OAuth2 Protected Resource'

    class BearerTokenMiddleware < Rack::OAuth2::Server::Resource::Bearer
      def initialize(app)
        super(app, Astoria::OAuth2.realm) do |req|
          req.access_token
        end
      end
    end

    class Error < StandardError
      attr_reader :headers, :wrapped
      delegate :status, :scheme, :realm, :error, :description, :uri, :protocol_params, to: :wrapped

      def initialize(wrapped)
        @headers = {}
        @resource = nil
        @wrapped = wrapped
      end

      def resource
        pp = protocol_params.reject { |key, val| val.blank? }
        pp if pp.any?
      end
    end

    class Unauthorized < Error
      def initialize(error = nil, description = nil, options = {})
        options.reverse_merge!(realm: Astoria::OAuth2.realm)
        super(Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(error, description, options))
        set_authenticate_header
      end

      protected
        def set_authenticate_header
          header = %Q{#{scheme} realm="#{realm}"}
          if Rack::OAuth2::Server::Resource::Bearer::ErrorMethods::DEFAULT_DESCRIPTION.keys.include?(error)
            header << %Q{ error="#{error}"}
            header << ", error_description=\"#{description}\"" if description.present?
            header << ", error_uri=\"#{uri}\""                 if uri.present?
          end
          headers['WWW-Authenticate'] = header
        end
    end

    module ErrorMethods
      include Rack::OAuth2::Server::Resource::ErrorMethods
      include Rack::OAuth2::Server::Resource::Bearer::ErrorMethods

      def unauthorized!(error = :forbidden, description = nil, options = {})
        raise Unauthorized.new(error, description, options)
      end
    end
  end
end
