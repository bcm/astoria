require 'rack/builder'

module Astoria
  class Service < Rack::Builder
    include Astoria::Logging

    def initialize!
      Dir.glob(File.join('.', 'config', 'initializers', '*.rb')).each {|file| require file}
    end
  end
end
