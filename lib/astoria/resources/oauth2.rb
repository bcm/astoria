require 'active_support/concern'
require 'astoria/oauth2'

module Astoria
  module Resources
    module OAuth2
      extend ActiveSupport::Concern
      include Astoria::OAuth2::ErrorMethods

      def require_oauth_token(options = {}, &block)
        token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
        unauthorized! unless token.present?
        @token = yield(token)
        invalid_token! unless @token.present?
      end

      included do
        attr_reader :current_token
      end

      module ClassMethods
        def require_oauth_token(options = {}, &block)
          before do
            require_oauth_token(options, &block)
          end
        end
      end
    end
  end
end
