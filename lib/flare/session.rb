module Flare
  class Session
    RESULT_LIMIT = 1000
    PER_PAGE = 16
    
    def initialize(url)
      @connection = RSolr.connect(:url => url)
    end
    
    attr_reader :connection
    
    delegate :commit, :optimize, :to => :connection

    def search_for_ids(*args)
      options = args.extract_options!
      ar_options = { :include => options.delete(:include) }
      response = execute(*args)
      Flare::Collection.ids_from_response(response, response[:request][:page], response[:request][:per_page], response[:request])
    end

    def search(*args)
      options = args.extract_options!
      ar_options = { :include => options.delete(:include) }
      response = execute(options)
      Flare::Collection.create_from_response(response, response[:request][:page], response[:request][:per_page], ar_options)
    end

    def count(*args)
      execute(*args)[:response][:numFound]
    end
    
    def index(*objects)
      objects = ensure_searchable(objects)
      objects.collect(&:to_solr_doc).each do |doc|
        # connection.update(RSolr::Message::Generator.new.add(doc[:fields], doc[:attributes]))
        connection.update(RSolr::Message::Builder.new.add(doc[:fields], doc[:attributes]))
        # connection.add(doc[:fields], doc[:attributes])
      end
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
        
        options.assert_valid_keys(:q, :fq, :types, :page, :per_page, :limit, :fl, :sort, :facet, :mlt, :mm)
        
        options.reverse_merge!({
          :page => 1,
          :per_page => PER_PAGE,
          :limit => RESULT_LIMIT,
          :fields => '* score',
        })

        query = {
          :q => Array(options[:q] || (args.blank? ? "*:*" : args)).flatten,
          :fq => Array(options[:fq]).flatten,
          :fl => options[:fields],
          :start => start = (options[:page] -1) * options[:per_page],
          :rows => options[:per_page],
          :sort => options[:sort]
        }
        
        if options[:facet]
          query["facet"] = true
          query["facet.field"] = options[:facet][:fields]
          query["facet.query"] = options[:facet][:queries]
          query["facet.mincount"] = options[:facet][:mincount] || 1
          query["facet.limit"] = options[:facet][:limit]
          
          query["facet.missing"] = @params[:facet][:missing]
          query["facet.mincount"] = @params[:facet][:mincount]
          query["facet.prefix"] = @params[:facet][:prefix]
          query["facet.offset"] = @params[:facet][:offset]
          query["facet.offset"] = 'count'
        end
        
        if options[:mlt]
          query['mlt'] = true
          query['mlt.fl'] = Array(options[:mlt][:fields]).flatten.join(',')
          query['mlt.count'] = options[:mlt][:count] if options[:mlt][:count]
        end
        
        if options[:mm]
          query['mm'] = options[:mm]
        end

        if options[:types]
          query[:fq] << Array(options[:types]).map {|type| "type:#{type}"}.join(" OR ")
        end
        
        Flare.log(<<-SOLR.squish)
          \e[4;32mSolr Query:\e[0;1m 
          #{query[:q].join(', ')} 
          #{"(#{query[:fq].join(' AND ')})," if query[:fq] } 
          sort: #{query[:sort]} 
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
