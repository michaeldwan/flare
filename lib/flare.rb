begin
  # require 'time'
  # require 'date'
  require 'rsolr'
rescue LoadError
  require 'rubygems'
  require 'rsolr'
end

%w(configuration collection index_builder session active_record).each do |file|
  require File.join(File.dirname(__FILE__), 'flare', file)
end

ActiveRecord::Base.send(:include, Flare::ActiveRecord)

module Flare
  class << self
    def session
      @session ||= Flare::Session.new
    end
    
    def indexed_models
      @@indexed_models ||= []
    end
  end
end