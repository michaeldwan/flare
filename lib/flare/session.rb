module Flare
  class Session
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
      Flare::Collection.ids_from_response(response, response[:request][:start], response[:request][:rows], response[:request])
    end

    def search(*args)
      options = args.extract_options!
      ar_options = { :include => options.delete(:include) }
      response = execute(options)
      Flare::Collection.create_from_response(response, response[:request][:start], response[:request][:rows], ar_options)
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

        options.reverse_merge!({
          :start => 0,
          :rows => PER_PAGE
        })
        
        options[:q] = Array.wrap(options[:q] || (args.blank? ? "*:*" : args))
        options[:fq] = Array.wrap(options.delete(:fq))

        if options[:types]
          options[:fq] << Array.wrap(options.delete(:types)).map {|type| "type:#{type}"}.join(" OR ")
        end
        
        Flare.log(<<-SOLR.squish)
          \e[4;32mSolr Query:\e[0;1m 
          #{options[:q].join(', ')} 
          #{"(#{options[:fq].join(' AND ')})," if options[:fq] } 
          sort: #{options[:sort]} 
          start: #{options[:start]},  
          rows: #{options[:rows]}
        SOLR

        response = connection.select(options)
        response[:request] = options
        response[:request][:page] = options[:start] + 1
        response[:request][:per_page] = options[:rows]

        response.with_indifferent_access
      end

      def ensure_searchable(*objects)
        Array(objects).flatten.select { |object| object.class.searchable? }
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
