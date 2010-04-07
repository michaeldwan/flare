module Flare
  class Collection < ::Array
    attr_reader :total_entries, :total_pages, :current_page, :per_page
    attr_accessor :response

    def initialize(page, per_page, total)
      @current_page, @per_page, @total_entries = page, per_page, total
      
      @total_pages = (@total_entries / @per_page.to_f).ceil
    end
    
    def self.ids_from_response(response, page, per_page, options)
      collection = self.new(page, per_page, response['response']['numFound'] || 0)
      collection.response = response
      collection.replace(response['response']['docs'].map {|doc| doc['id']})
      return collection
    end
    
    def self.create_from_response(response, page, per_page, options)
      # raise response.inspect
      collection = self.new(page, per_page, response['response']['numFound'] || 0)
      collection.response = response      
      collection.replace(instantiate_objects(response, options))
      return collection
    end
    
    def max_pages=(value)
      @total_pages = value if value < @total_pages
    end
    
    def previous_page 
      current_page > 1 ? (current_page - 1) : nil
    end
    
    def next_page
      current_page < total_pages ? (current_page + 1): nil
    end
    
    def offset
      (current_page - 1) * @per_page
    end
    
    private
      def self.instantiate_objects(response, options = {})
        types = Hash.new{|h, k| h[k] = []}
        results = Hash.new{|h, k| h[k] = {}}
        response['response']['docs'].map do |doc|
          type, id = doc['id'].split(':')
          types[type] << id
        end
        
        types.each do |type, ids|
          includes = options[:include]
          type.constantize.find_all_by_id(ids, :include => includes).each do |item|
            results[type][item.id] = item
          end
        end

        response['response']['docs'].map do |doc|
          type, id = doc['id'].split(':')
          results[type][id.to_i]
        end.compact
      end
  end
end
