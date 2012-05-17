require 'sequel'

module Astoria
  module Integrations
    module Sequel
      include Astoria::Logging

      ::Sequel::Model.plugin :timestamps, update_on_create: true
      ::Sequel::Model.raise_on_save_failure = true
      ::Sequel.extension :pagination
      ::Sequel.application_timezone = :utc
      ::Sequel.database_timezone = :utc

      @@db = {}
      @@config = {}

      class << self
        def config(role = :default)
          unless @@config.key?(role)
            segments = ['.', 'config']
            segments += role == :default ? ['database.yml'] : ['database', "#{role}.yml"]
            file = File.join(segments)
            logger.debug "Loading config for #{role} database from #{file}"
            @@config[role] ||= YAML.load_file(file)[ENV['RACK_ENV'].to_s]
          end
          @@config[role]
        end

        def migrations_dir
          File.join('.', 'db', 'migrations')
        end

        def url(role = :default)
          cfg = config(role)
          sprintf("%s://%s:%s@%s/%s", cfg['adapter'], cfg['username'], cfg['password'], cfg['host'], cfg['database'])
        end

        def connect!(role = :default, options = {}, &block)
          cfg = config(role)
          connect_options = {
            adapter:      cfg['adapter'],
            user:         cfg['username'],
            password:     cfg['password'],
            host:         cfg['host'],
            database:     cfg['database'],
            encoding:     cfg['encoding'],
            pool_timeout: cfg['timeout'],
            single_threaded: true,
            max_connections: 1,
            loggers:      (options[:silence_logging] ? nil : [Astoria.logger]),
            after_connect: lambda {|conn| logger.debug "Connected to db with connection #{conn.inspect}"}
          }.merge(options)

          @@db[role] = ::Sequel.connect(connect_options)
        end

        def db(role = :default)
          @@db[role]
        end

        def disconnect!(role = :default)
          @@db[role].disconnect if @@db[role]
        end

        def silence_logging(&block)
          old_loggers = connection.loggers
          connection.loggers = []
          begin
            yield
          ensure
            connection.loggers = old_loggers
          end
        end
      end
    end
  end
end
