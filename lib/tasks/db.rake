
MONGO_DB = HashWithIndifferentAccess.new(YAML::load_file(File.join(Rails.root, 'config', 'mongoid.yml')))[Rails.env]

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
      mongo 'db.createCollection("tweets", {capped:true, max: 100000})'
      Rake::Task['db:mongoid:create_indexes'].invoke
    end
    
  end
end