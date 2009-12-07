module Flare
  class Session
    RESULT_LIMIT = 1000
    PER_PAGE = 16
    
    def connection
      @connection ||= RSolr.connect(:url => Flare::Configuration.client.url)
    end

    delegate :commit, :optimize, :to => :connection

    def search_for_ids(*args)
      response = execute(*args)
      Flare::Collection.ids_from_response(response, response[:request][:page], response[:request][:per_page], response[:request])
    end

    def search(*args)
      response = execute(*args)
      Flare::Collection.create_from_response(response, response[:request][:page], response[:request][:per_page], response[:request])
    end

    def count(*args)
      execute(*args)[:response][:numFound]
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
      def execute(*args)
        options = args.extract_options!
        
        options.reverse_merge!({
          :page => 1,
          :per_page => PER_PAGE,
          :limit => RESULT_LIMIT,
          :fields => '* score',
        })

        options.assert_valid_keys(:filter, :types, :page, :per_page, :limit, :fields, :order, :facet)
        
        query = {
          :q => args,
          :fq => Array(options[:filter]).flatten,
          :fl => options[:fields],
          :start => start = (options[:page] -1) * options[:per_page],
          :rows => options[:per_page]
        }
        
        if options[:facets]
          query[:facets] = true
          query['facet.field'] = options[:facets][:fields]
          query['facet.query'] = options[:facets][:queries]
          query['facet.mincount'] = options[:facets][:mincount] || 1
          query["facet.limit"] = options[:facets][:limit]
          
          query["facet.missing"] = @params[:facets][:missing]
          query["facet.mincount"] = @params[:facets][:mincount]
          query["facet.prefix"] = @params[:facets][:prefix]
          query["facet.offset"] = @params[:facets][:offset]
        end        
        
        
        if options[:types]
          query[:fq] << Array(options[:types]).map {|type| "type:#{type}"}.join(" OR ")
        end
        
        query[:q] = query.delete(:fq) if query[:q].blank?
        
        ::ActiveRecord::Base.logger.debug(<<-SOLR.squish)
          \e[4;32mSolr Query:\e[0;1m 
          #{query[:q].join(', ')} 
          #{"(#{query[:fq].join(' AND ')})," if query[:fq] } 
          sort: #{query[:order]} 
          start: #{query[:start]}, 
          rows: #{query[:rows]}
        SOLR

        response = connection.select(query)
        response[:request] = query
        response[:request][:page] = options[:page]
        response[:request][:per_page] = options[:per_page]
        response.with_indifferent_access
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
