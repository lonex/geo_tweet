rails_root = File.expand_path('../..', __FILE__)
if ENV['RAILS_ENV'] == 'development'
  worker_processes 1
else
  worker_processes 5
end

working_directory rails_root

# This loads the application in the master process before forking
# worker processes
# Read more about it here:
# http://unicorn.bogomips.org/Unicorn/Configurator.html
preload_app false

timeout 30

pid "#{rails_root}/tmp/pids/unicorn.pid"

before_fork do |server, worker|
end

after_fork do |server, worker|
end
