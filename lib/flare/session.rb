module Flare
  class Session
    RESULT_LIMIT = 1000
    PER_PAGE = 16
    
    def connection
      @connection ||= RSolr.connect(:url => Flare::Configuration.client.url)
    end

    delegate :commit, :optimize, :to => :connection

    def search_for_ids(query = {})
      query = prepare_query(query)
      response = Search.execute(query)
      Flare::Collection.ids_from_response(response, query[:page], query[:per_page], query)
    end

    def search(query = {})
      query = prepare_query(query)
      response = Search.execute(query)
      Flare::Collection.create_from_response(response, query[:page], query[:per_page], query)
    end

    def count(query = {})
      query[:page] ||= query[:page] ? query[:page].to_i : 1
      query[:per_page] ||= PER_PAGE
      query[:limit] ||= RESULT_LIMIT
      
      execute(query)[:response][:numFound]
    end
    
    def index(*objects)
      objects = ensure_searchable(objects)
      connection.add(objects.collect(&:to_solr_doc))
    end
    
    def index!(*objects)
      index(objects)
      commit
    end
    
    def remove(*objects)
      objects = ensure_searchable(objects)
      connection.delete_by_id(objects.collect(&:solr_document_id))
    end
    
    def remove!(*objects)
      remove(objects)
      commit
    end
    
    def remove_all(*types)
      types = Array(types).flatten.select { |type| type.searchable? }
      connection.delete_by_query(types.map { |type| "type:#{type.name}" }.join(' OR '))
    end
    
    def remove_all!(*types)
      remove_all(types)
      commit
      optimize
    end
    
    private
      def execute(query)
        query.assert_valid_keys(:terms, :types, :page, :per_page, :limit, :fields, :order)

        raw_query = "(#{query[:terms]})"
        if query[:types]
          raw_query << " AND (#{Array(query[:types]).map {|type| "type:#{type}"}.join(" OR ") })"
        end
        
        start = (query[:page] -1) * query[:per_page]
        rows = query[:per_page]
        field_query = query[:fields]

        ActiveRecord::Base.debug("\e[4;32mSolr Query:\e[0;1m #{raw_query}, sort: #{query[:order]} start: #{start}, rows: #{rows}")

        connection.select(:q => raw_query, :fl => field_query, :start => start, :rows => rows, :sort => query[:order])
      end
      
      def ensure_searchable(*objects)
        Array(objects).flatten.select { |object| object.class.searchable? }
      end
      
      def prepare_query(query)
        query[:page] ||= query[:page] ? query[:page].to_i : 1
        query[:per_page] ||= PER_PAGE
        query[:limit] ||= RESULT_LIMIT
        query[:fields] ||= '* score'
        query
      end

      # I dont like this... Can we move it to hash if a library like ActiveSupport doesn't already have it?
      def symbolize_keys(hash)
        hash.inject({}){|result, (key, value)|  
          new_key = case key  
                    when String then key.to_sym  
                    else key  
                    end  
          new_value = case value  
                      when Hash then symbolize_keys(value)  
                      else value  
                      end  
          result[new_key] = new_value  
          result  
        }  
      end
  end
end
