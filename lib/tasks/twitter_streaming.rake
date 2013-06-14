require 'tweetstream'
require File.expand_path('./app/helpers/tweet_helper', Rails.root)

module StreamTask
  extend self

  def exit_task
    puts "Exiting..."
    exit 1
  end

  def config
    TweetStream.configure do |config|
      config.consumer_key       = TWITTER_CONFIG[:app_id]
      config.consumer_secret    = TWITTER_CONFIG[:app_secret]
      config.oauth_token        = TWITTER_CONFIG[:access_token]
      config.oauth_token_secret = TWITTER_CONFIG[:token_secret]
      config.auth_method        = :oauth
    end
    yield
  end

  module ErrorHandlers
    def rate_limit_handler skipped_nr
      # puts "rate_limit_handler #{skipped_nr}"  
    end
    def error_handler msg
      puts "error_handler #{msg}"
    end
  end

  class Job
    include TweetHelper
    include ErrorHandlers
    
    def run
      stream = Fiber.new do
        TweetStream::Client.new.on_limit {|skipped_nr|
          rate_limit_handler skipped_nr
        }.on_error {|msg|
          error_handler msg
        }.locations(-180.0,-90.0,180.0,90.0) do |status|
          unless status.geo.nil?
            Fiber.yield status
          end
        end
      end
          
      count = 0
      while status = stream.resume
        raw_tweet_to_tweet(status).save
        count += 1
        puts "#{Time.now}, #{count}" if count % 1000 == 0
      end
    end
  end
  
end


namespace :twitter do

  desc 'connect to Twitter streaming API endpoint'
  task :stream => :environment do
    trap("SIGINT") { StreamTask.exit_task }
    StreamTask.config do
      StreamTask::Job.new.run
    end
  end

end