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
      build_routing_table
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
          File.join(root, 'service', 'entities'),
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

      def build_routing_table
        ObjectSpace.each_object(Class).
          select { |klass| klass < Astoria::Resource && klass.name.present? }.
          map { |resource| [resource, resource.root_relative_resource_path] }.
          sort_by { |it| -it.last.length }.
          each { |it| routes.add(it.first) }
      end

    class Routes < SimpleDelegator
      include Astoria::Logging

      def initialize
        super(Rack::Routes.new)
      end

      def add(resource, options = {})
        path = "#{resource.root_relative_resource_path}"
        path = "/#{path}" unless path == '/'
        # /events/:slug/games => %r{^/events/(?<slug>[^/]+)/games}
        regexp = Regexp.new(path.gsub(%r{/:([^/]+)}, '/(?<\1>[^/]+)'))

#        logger.debug "adding route at #{path} for #{resource}"

        __getobj__.class.location(regexp) do |env|
          matchdata = env['routes.location.matchdata']

          env['SCRIPT_NAME'] = matchdata[0]
          env['PATH_INFO'] = env['PATH_INFO'].sub(env['SCRIPT_NAME'], '')

          matches = resource.route_matches
          if matches
            env['astoria.routes.matches'] = HashWithIndifferentAccess.new
            matches.each_with_index do |match, i|
              env['astoria.routes.matches'][match] = matchdata[i+1]
            end
          end

#          logger.debug "Calling resource #{resource} for path #{env['SCRIPT_NAME']}"

          resource.call(env)
        end
      end
    end
  end
end
