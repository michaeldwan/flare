module Flare
  module ActiveRecord
    def self.included(base)
      base.extend Hook
    end

    module Hook
      def searchable(&block)
        Flare.indexed_models << self unless Flare.indexed_models.include?(self)
        
        builder = IndexBuilder.new(&block)
        solr_index = builder.index
        
        write_inheritable_attribute :solr_index, solr_index
        class_inheritable_reader :solr_index
        
        after_save :solr_save
        after_destroy :solr_destroy
        
        include InstanceMethods
        extend ClassMethods
      end
      
      def searchable?
        false
      end
    end
    
    module ClassMethods
      def search_for_ids(*args)
        options = args.extract_options!
        options[:types] ||= []
        options[:types] << self
        Flare.session.search_for_ids(*[args, options].flatten)
      end

      def search(*args)
        options = args.extract_options!
        options[:types] ||= []
        options[:types] << self
        Flare.session.search(*[args, options].flatten)
      end

      def search_count(*args)
        options = args.extract_options!
        options[:types] ||= []
        options[:types] << self
        Flare.session.count(*[args, options].flatten)
      end
      
      def searchable?
        true
      end
      
      def rebuild_solr_index
        total = self.count
        count = 0
        self.find_in_batches(:batch_size => 100) do |batch|
          Flare.session.index(batch)
          count += batch.length
          printf "\r#{count}/#{total} complete"
          STDOUT.flush
        end
        puts
        Flare.session.commit
        Flare.session.optimize
      end
      
      def clear_solr_index
        Flare.session.remove_all!(self)
      end
    end
    
    module InstanceMethods
      def to_solr_doc
        doc = { :id => solr_document_id, :type => self.class.name }
        solr_index[:fields].each do |field|
          value = send(field[:source])
          # Need to convert dates to utc xmlschema.
          #TODO: move this translation to rsolr gem
          if value.respond_to?(:utc)
            value = value.utc.xmlschema
          end
          doc[field[:name]] = value
        end
        doc
      end
      
      def solr_document_id
        "#{self.class.name}:#{self.id}"
      end
      
      def solr_save
        Flare.session.index!(self)
      end
      
      def solr_destroy
        Flare.session.remove!(self)
      end
    end
  end
end
