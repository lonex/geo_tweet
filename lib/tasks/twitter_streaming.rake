require 'tweetstream'
require 'fiber'
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
    
    def rate_limit_handler missed_counts_since_connection
      # puts "rate_limit_handler #{missed_counts_since_connection}"  
    end
    
    def error_handler msg
      puts "error_handler #{msg}"
    end

    def reconnect_error_handler timeout, retries
      puts "reconnect_error_handler maximum reconnect #{retries} reached, abort"
      exit 1
    end
  end


  class Job
    include TweetHelper
    include ErrorHandlers
    # for reporting
    CHUNK = 1000

    def stop
      @client.stop if @client
    end

    def exclude_cached_status status
      @cached_status ||= {}
      if @cached_status[status.id]
        puts "Warning duplicated status detected"
      else
        @cached_status[status.id] = true
        yield(status)
      end
    end

    def report_progress
      yield
      @count += 1
      if @count % CHUNK == 0
        puts "#{@count} tweets in total, #{Time.now - @start} secs"
        @start = Time.now
      end
    end

    # 
    # Case 1: use EM and fiber
    # TweetStream::Client initializes and starts the main EM event loop. The status handler block is the 
    # callback which gets handled by the custom EM::Connection#receive_data defined in the em-twitter
    # Gem. In the middle of the status handler, the fiber yields to the main thread by passing it the 
    # latest status retrieved from TW Streaming API. The main thread persists the status and resumes
    # the fiber which continues the EM event loop.
    #
    def run
      @count = 0
      @start = Time.now

      stream = Fiber.new do
        @client = TweetStream::Client.new.on_limit {|missed_counts|
          rate_limit_handler missed_counts
        }.on_error {|msg|
          error_handler msg
        }.on_reconnect {|timeout, retries|
          reconnect_error_handler timeout, retries
        }.locations(-180.0,-90.0,180.0,90.0) do |status|
          unless status.geo.nil?
            Fiber.yield status
          end
        end
      end
      
      while status = stream.resume
        exclude_cached_status(status) do
          report_progress do
            raw_tweet_to_tweet(status).save
          end
        end
      end
    end

    #
    # Case 2: baseline
    # This is used as a benchmark baseline of how fast the client consumes the status inflow
    # from the TW streaming server. It's a simple usecase of using TweetStream.
    #
    def run2
      @count = 0; @start = Time.now
      @client = TweetStream::Client.new.on_limit {|missed_counts|
          rate_limit_handler missed_counts
      }.on_error {|msg|
         error_handler msg
      }.on_reconnect {|timeout, retries|
         reconnect_error_handler timeout, retries
      }.locations(-180.0,-90.0,180.0,90.0) do |status|
         unless status.geo.nil?
           exclude_cached_status(status) do
              report_progress do
                raw_tweet_to_tweet(status).save
              end
            end
         end
      end
    end

    #
    # Case 3: use EM.defer
    # In cases that the database insertion is too expensive that could eventually block the EM event 
    # loop. The status processing block is wrapped inside the EM.defer setup. i.e. The database insertion
    # happens inside one of the thread in EM's thread pool. It runs in the background. It won't block
    # the main EM event loop. But the status might be inserted into the database in an order different
    # from the order that the tweets arrive.
    #
    def run3
      @count = 0
      @start = Time.now

      # No need to enclose the following in a EM.run block b/c TweetStream does this when 
      # it initializes the client.
      @client = TweetStream::Client.new.locations(-180.0,-90.0,180.0,90.0) do |status|
        unless status.geo.nil?
          EM.defer do
            exclude_cached_status(status) do
              # We cannot use report_progress as the variable @count is not thread-safe. Performance
              # profiling is little bit more complex that that of the other 2 cases.
              raw_tweet_to_tweet(status).save
            end
          end
        end
      end
      
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

  # Case 2
  task :stream2 => :environment do
    job = StreamTask::Job.new
    trap("SIGINT") { job.stop; StreamTask.exit_task }
    StreamTask.config do
      job.run2
    end
  end

  # Case 3
  task :stream3 => :environment do
    job = StreamTask::Job.new
    trap("SIGINT") { job.stop; StreamTask.exit_task }
    StreamTask.config do
      job.run3
    end
  end


end