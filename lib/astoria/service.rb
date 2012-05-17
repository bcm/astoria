require 'rack/routes'

module Astoria
  class Service < SimpleDelegator
    include Astoria::Logging

    attr_reader :routes

    def initialize
      super(Rack::Routes)
      @routes = Routes.new
    end

    def initialize!
      load_initializers
      load_routes
    end

    protected
      def load_initializers
        Dir.glob(File.join('.', 'config', 'initializers', '*.rb')).each {|file| require file}
      end

      def load_routes
        require File.join('.', 'config', 'routes.rb')
      end
  end

  class Routes
    include Astoria::Logging

    def draw(&block)
      instance_eval(&block)
    end

    def resource(pattern, klass, options = {})
      # /events/:slug/games => %r{^/events/(?<slug>[^/]+)/games}
      regexp = Regexp.new(pattern.gsub(%r{/:([^/]+)}, '/(?<\1>[^/]+)'))

      # XXX: require the resource file - means the resources dir has to be in the load path
      # require "myapp/resources/#{name}_resource"

      # XXX: allow :foo instead of MyApp::FooResource
      # klass = "myapp/#{name}_resource".camelize.constantize

      Rack::Routes.location regexp do |env|
        matchdata = env['routes.location.matchdata']

        env['SCRIPT_NAME'] = matchdata[0]
        env['PATH_INFO'] = env['PATH_INFO'].sub(env['SCRIPT_NAME'], '')

        if options[:matches]
          env['astoria.routes.matches'] = HashWithIndifferentAccess.new
          Array(options[:matches]).each_with_index do |match, i|
            env['astoria.routes.matches'][match] = matchdata[i+1]
          end
        end

        klass.call(env)
      end
    end
  end
end
