begin
  # require 'time'
  # require 'date'
  require 'rsolr'
rescue LoadError
  require 'rubygems'
  require 'rsolr'
end

%w(configuration).each do |file|
  require File.join(File.dirname(__FILE__), 'flare', file)
end
