require 'active_support/all'
require 'active_support/dependencies'
require 'rack/routes'

module Astoria
  mattr_accessor :service
  @@service = nil

  class Service
    include Astoria::Logging

    attr_reader :routes, :root
    delegate :call, to: :routes

    def initialize(root)
      @routes = Routes.new
      @root = File.expand_path(root)
    end

    def initialize!
      load_initializers
      load_resources
    end

    def self.create(root)
      Astoria.service = new(root)
    end

    protected
      def load_initializers
        Dir.glob(File.join(root, 'config', 'initializers', '*.rb')).each { |file| require file }
      end

      def load_resources
        load_paths = [
          File.join(root, 'lib'),
          File.join(root, 'service', 'models'),
          File.join(root, 'service', 'resources')
        ]

        $LOAD_PATH.unshift(*load_paths)
        ActiveSupport::Dependencies.autoload_paths.unshift(*load_paths)

        # eager load everything
        load_paths.each do |path|
          matcher = /\A#{Regexp.escape(path)}\/(.*)\.rb\Z/
          Dir.glob(File.join(path, '**', '*.rb')).sort.each do |file|
            require_dependency(file.sub(matcher, '\1'))
          end
        end
      end

    class Routes < SimpleDelegator
      include Astoria::Logging

      def initialize
        super(Rack::Routes.new)
      end

      def draw(&block)
        instance_eval(&block)
      end

      def resource(app, options = {})
        # /events/:slug/games => %r{^/events/(?<slug>[^/]+)/games}
        regexp = Regexp.new(app.resource_path.gsub(%r{/:([^/]+)}, '/(?<\1>[^/]+)'))

        __getobj__.class.location(regexp) do |env|
          matchdata = env['routes.location.matchdata']

          env['SCRIPT_NAME'] = matchdata[0]
          env['PATH_INFO'] = env['PATH_INFO'].sub(env['SCRIPT_NAME'], '')

          if options[:matches]
            env['astoria.routes.matches'] = HashWithIndifferentAccess.new
            Array(options[:matches]).each_with_index do |match, i|
              env['astoria.routes.matches'][match] = matchdata[i+1]
            end
          end

          app.call(env)
        end
      end
    end
  end
end
