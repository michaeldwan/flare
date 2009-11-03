require 'yaml'

module Flare
  class Configuration
    class << self
      attr_reader :client, :server
      
      def server(reload = false)
        @server = nil if reload
        @server ||= Server.new
      end

      def client(reload = false)
        @client = nil if reload
        @client = Client.new
      end
    end

    private
      class Server
        def initialize
          @config = YAML::load_file(File.join(Rails.root, 'config', 'solr.yml'))[Rails.env]
        end

        def port
          @port ||= (@config['port'] || 8983).to_i
        end

        def log_dir
          @log_dir ||= File.expand_path(@config['log_dir'] || 'log')
        end

        def log_level
          @log_level ||= @config['log_level'] || 'INFO'
        end

        def data_dir
          @data_dir ||= File.expand_path(@config['data_dir'] || File.join('solr', 'data', Rails.env))
        end

        def solr_home
          @solr_home ||= File.expand_path(@config['solr_home'] || File.join(File.dirname(__FILE__), '..', '..', 'solr', 'solr'))
        end

        def pid_dir
          @pid_dir ||= File.expand_path(@config['pid_dir'] || 'tmp/pids')
        end

        def jvm_options
          @jvm_options ||= @config['jvm_options']
        end        
      end

      class Client
        def initialize
          @config = YAML::load_file(File.join(Rails.root, 'config', 'flare.yml'))[Rails.env]
        end

        def port
          @port ||= (@config['port'] || 8983).to_i
        end

        def host
          @host ||= @config['host'] || '127.0.0.1'
        end

        def path
          @path ||= @config['path'] || 'solr'
        end
        
        def url
          @url ||= "http://#{host}:#{port}/#{path}"
        end
      end
  end
end
