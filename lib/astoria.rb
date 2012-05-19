module Astoria
  autoload :Logging, 'astoria/logging'
  autoload :OAuth2, 'astoria/oauth2'
  autoload :Service, 'astoria/service'

  autoload :Content, 'astoria/content'
  autoload :CountQuery, 'astoria/content/count_query'
  autoload :Entity, 'astoria/content/entity'
  autoload :Errors, 'astoria/content/errors'
  autoload :GroupedQuery, 'astoria/content/grouped_query'
  autoload :PagedQuery, 'astoria/content/paged_query'

  autoload :MediaType, 'astoria/providers/media_type'
  autoload :MediaTypes, 'astoria/providers/media_type'

  autoload :Resource, 'astoria/resources/base'

  def self.env
    @env ||= Env.new
  end

  class Env
    attr_reader :env

    def initialize
      @env = (ENV['RACK_ENV'] || :development).to_sym
    end

    def method_missing(meth, *args)
      meth = meth.to_s
      if meth.end_with?('?')
        env.to_s == meth.chop
      else
        super
      end
    end
  end
end
