require 'active_support/concern'
require 'log_weasel'

module Astoria
  class << self
    def default_logger
      LogWeasel::BufferedLogger.new($stdout)
    end

    def logger
      @logger ||= default_logger
    end

    def logger=(logger)
      @logger = logger
    end
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
