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
          query['facet.mincount'] = options[:facets][:mincount]
          query["facet.limit"] = options[:facets][:limit]
          
          query["facet.missing"] = @params[:facets][:missing]
          query["facet.mincount"] = @params[:facets][:mincount]
          query["facet.prefix"] = @params[:facets][:prefix]
          query["facet.offset"] = @params[:facets][:offset]

          
          #   hash["facet.field"] = []
          #   hash["facet.query"] = @params[:facets][:queries]
          #   hash["facet.sort"] = (@params[:facets][:sort] == :count) if @params[:facets][:sort]
          
        end
        
        
        
        
        # # facet parameter processing
        # if @params[:facets]
        #   # TODO need validation of all that is under the :facets Hash too
        #   hash[:facet] = true
        #   hash["facet.field"] = []
        #   hash["facet.query"] = @params[:facets][:queries]
        #   hash["facet.sort"] = (@params[:facets][:sort] == :count) if @params[:facets][:sort]
        #   hash["facet.limit"] = @params[:facets][:limit]
        #   hash["facet.missing"] = @params[:facets][:missing]
        #   hash["facet.mincount"] = @params[:facets][:mincount]
        #   hash["facet.prefix"] = @params[:facets][:prefix]
        #   hash["facet.offset"] = @params[:facets][:offset]
        #   if @params[:facets][:fields]  # facet fields are optional (could be facet.query only)
        #     @params[:facets][:fields].each do |f|
        #       if f.kind_of? Hash
        #         key = f.keys[0]
        #         value = f[key]
        #         hash["facet.field"] << key
        #         hash["f.#{key}.facet.sort"] = (value[:sort] == :count) if value[:sort]
        #         hash["f.#{key}.facet.limit"] = value[:limit]
        #         hash["f.#{key}.facet.missing"] = value[:missing]
        #         hash["f.#{key}.facet.mincount"] = value[:mincount]
        #         hash["f.#{key}.facet.prefix"] = value[:prefix]
        #         hash["f.#{key}.facet.offset"] = value[:offset]
        #       else
        #         hash["facet.field"] << f
        #       end
        #     end
        #   end
        # end
        
        
        
        
        if options[:types]
          query[:fq] << Array(options[:types]).map {|type| "type:#{type}"}.join(" OR ")
        end
        
        ::ActiveRecord::Base.logger.debug("\e[4;32mSolr Query:\e[0;1m #{query[:q].join(', ')} (#{query[:fq].join(' AND ')}), sort: #{query[:order]} start: #{query[:start]}, rows: #{query[:rows]}")

        response = connection.select(query)
        response[:request] = query
        response[:request][:page] = options[:page]
        response[:request][:per_page] = options[:per_page]
        puts response.inspect
        response
      end

      # def execute(query)
      #   query.assert_valid_keys(:terms, :types, :page, :per_page, :limit, :fields, :order)
      # 
      #   raw_query = "(#{query[:terms]})"
      #   if query[:types]
      #     raw_query << " AND (#{Array(query[:types]).map {|type| "type:#{type}"}.join(" OR ") })"
      #   end
      #   
      #   start = (query[:page] -1) * query[:per_page]
      #   rows = query[:per_page]
      #   field_query = query[:fields]
      # 
      #   ::ActiveRecord::Base.logger.debug("\e[4;32mSolr Query:\e[0;1m #{raw_query}, sort: #{query[:order]} start: #{start}, rows: #{rows}")
      # 
      #   connection.select(:q => raw_query, :fl => field_query, :start => start, :rows => rows, :sort => query[:order])
      # end

      
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
