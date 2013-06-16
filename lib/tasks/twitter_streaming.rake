require 'tweetstream'
require 'fiber'
require File.expand_path('./app/helpers/tweet_helper', Rails.root)

require 'em-http'

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
    def rate_limit_handler missed_counts_since_connection
      puts "rate_limit_handler #{missed_counts_since_connection}"  
    end
    def error_handler msg
      puts "error_handler #{msg}"
    end
  end

  class Job
    include TweetHelper
    include ErrorHandlers
    CHUNK = 1000

    def run
      stream = Fiber.new do
        @client = TweetStream::Client.new.on_limit {|missed_counts|
          rate_limit_handler missed_counts
        }.on_error {|msg|
          error_handler msg
        }.locations(-180.0,-90.0,180.0,90.0) do |status|
          unless status.geo.nil?
            Fiber.yield status
          end
        end
      end
      
      tws = {}
      count = 0
      while status = stream.resume
        raw_tweet_to_tweet(status).save
        count += 1
        puts "#{Time.now} #{count} tweets" if count % CHUNK == 0
        if tws[status.id]
          puts "Warning tweet exists already."
        else
          tws[status.id] = true
        end
      end
    end

    #
    # This is used as a benchmark baseline of how fast the client consumes the streaming 
    # status inflow.
    #
    def run2
      count = 0; start = Time.now
      @client = TweetStream::Client.new.on_limit {|missed_counts|
          rate_limit_handler missed_counts
      }.on_error {|msg|
         error_handler msg
      }.locations(-180.0,-90.0,180.0,90.0) do |status|
         unless status.geo.nil?
           raw_tweet_to_tweet(status).save
           count += 1

           if count % 1000 == 0
             diff = Time.now - start
             puts "#{count} tweets so far, 1000 took #{diff} secs"
             start = Time.now
           end
         end
      end
    end

    def stop
      @client.stop if @client
    end

  end
  
end


namespace :twitter do

  desc 'Get geo tagged tweets from Twitter streaming API'
  task :stream => :environment do
    job = StreamTask::Job.new
    trap("SIGINT") { job.stop; StreamTask.exit_task }
    StreamTask.config do
      job.run
    end
  end

  task :stream2 => :environment do
    job = StreamTask::Job.new
    trap("SIGINT") { job.stop; StreamTask.exit_task }
    StreamTask.config do
      job.run2
    end
  end

end