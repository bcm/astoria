require 'active_support/concern'
require 'log_weasel'

module Astoria
  def self.default_logger
    if env.test?
      Dir.mkdir('log') unless File.exists?('log')
      LogWeasel::BufferedLogger.new(File.join('log', 'test.log'))
    else
      LogWeasel::BufferedLogger.new($stdout)
    end
  end

  def self.logger
    @logger ||= default_logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  module Logging
    extend ActiveSupport::Concern

    def logger
      self.class.logger
    end

    module ClassMethods
      def logger
        Astoria.logger
      end
    end
  end
end
