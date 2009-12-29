require 'escape'

namespace :flare do
  desc 'Rebuild the Solr index for all searchable models'
  task :rebuild_index => :environment do      
    Flare.indexed_models.each do |model|
      puts "Clearing index for #{model.name}..."
      model.clear_solr_index

      puts "Rebuilding index for #{model.name}..."
      model.rebuild_solr_index        
    end

    puts "Optimizing..."
    Flare.session.commit
    Flare.session.optimize
  end
end
