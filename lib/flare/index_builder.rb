module Flare
  class IndexBuilder
    attr_reader :fields

    def initialize(&block)
      @fields = []
      @attributes = {}
      self.instance_eval(&block) if block_given?
    end

    def index
      { :fields => @fields, :attributes => @attributes }
    end

    protected
      def field(*args)
        field, options = args.first, args.extract_options!
        @fields << {
          :source => field, 
          :name => options[:as] || field, 
          :boost => options[:boost] || nil
          }
      end
      
      def attribute(name, value)
        @attributes[name] = value
      end
  end
end
