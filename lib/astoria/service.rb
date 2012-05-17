require 'rack/builder'

module Astoria
  class Service < Rack::Builder
    def initialize!
      Dir.glob(File.join('.', 'config', 'initializers', '*.rb')).each {|file| require file}
    end
  end
end
