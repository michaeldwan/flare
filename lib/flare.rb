begin
  # require 'time'
  # require 'date'
  require 'rsolr'
rescue LoadError
  require 'rubygems'
  require 'rsolr'
end

%w(collection index_builder session active_record).each do |file|
  require File.join(File.dirname(__FILE__), 'flare', file)
end

ActiveRecord::Base.send(:include, Flare::ActiveRecord)

module Flare
  class << self

    attr_reader :solr_url
    
    def solr=(value)
      @session = Flare::Session.new(value)
    end
    
    def session
      return @session if @session
      self.solr = "http://127.0.0.1:8983/solr"
      @session
    end
    
    def indexed_models
      @@indexed_models ||= []
    end
    
    def log(message)
      if Object.const_defined?("ActiveRecord")
        ::ActiveRecord::Base.logger.debug(message)
      else
        puts message
      end
    end
  end
end