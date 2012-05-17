require 'active_support/concern'
require 'astoria/oauth2'

module Astoria
  module Resources
    module OAuth2
      extend ActiveSupport::Concern
      include Astoria::OAuth2::ErrorMethods

      def require_oauth_token
        @current_token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
        unauthorized! unless @current_token
      end

      def current_token
        @current_token
      end

      module ClassMethods
        def require_oauth_token
          before do
            require_oauth_token
          end
        end
      end
    end
  end
end
