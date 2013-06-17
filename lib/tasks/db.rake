
MONGO_DB = HashWithIndifferentAccess.new(YAML::load_file(File.join(Rails.root, 'config', 'mongoid.yml')))[Rails.env]
CAPPED_COLLECTIONS = HashWithIndifferentAccess.new(YAML::load_file(File.join(Rails.root, 'config', 'capped_collections.yml')))[Rails.env]

def mongo cmd
  sh "mongo #{MONGO_DB[:sessions][:default][:hosts].first}/#{MONGO_DB[:sessions][:default][:database]} --eval '#{cmd}'"
end


namespace :db do
  namespace :mongo do

    desc 'drop the MongoDB database'
    task :drop => :environment do
      mongo 'db.dropDatabase()'
    end

    desc 'create the MongoDB database'
    task :init => :environment do
      max = CAPPED_COLLECTIONS[:tweets]
      # Assume each tweet size is 1024 bytes
      size = max * 1024
      
      # Mongoid 3.x dropped store_in for capped collection. We do it here.
      # https://github.com/mongoid/mongoid/issues/2917
      mongo 'db.createCollection("tweets", {capped:true, size: %s, max: %s})' % [size, max]
      Rake::Task['db:mongoid:create_indexes'].invoke
    end
    
  end
end