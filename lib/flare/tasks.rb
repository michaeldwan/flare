require 'escape'

namespace :flare do
  namespace :solr do
    desc 'Start the Solr instance'
    task :start => :environment do
      solr_home = Flare::Configuration.server.solr_home
      data_dir = Flare::Configuration.server.data_dir
      pid_dir = Flare::Configuration.server.pid_dir
      port = Flare::Configuration.server.port 
      log_file = File.join(Flare::Configuration.server.log_dir, 'solr.log')
      log_level = Flare::Configuration.server.log_level

      [data_dir, pid_dir].each { |path| FileUtils.mkdir_p(path) }
      
      command = ['flare-solr', 'start', '-p', port.to_s, '-d', data_dir, '--pid-dir', pid_dir, '-l', log_level, '--log-file', log_file]
      if solr_home
        command << '-s' << solr_home
      end
      system(Escape.shell_command(command))
    end

    desc 'Run the Solr instance in the foreground'
    task :run => :environment do
      data_path = Flare::Configuration.server.data_dir
      solr_home = Flare::Configuration.server.solr_home
      port = Flare::Configuration.server.port
      
      FileUtils.mkdir_p(data_path)
      command = ['flare-solr', 'run', '-p', port.to_s, '-d', data_path]
      if solr_home
        command << '-s' << solr_home
      end
      exec(Escape.shell_command(command))
    end

    desc 'Stop the Solr instance'
    task :stop => :environment do
      FileUtils.cd(Flare::Configuration.server.pid_dir) do
        system(Escape.shell_command(['flare-solr', 'stop']))
      end
    end
  end
    
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
