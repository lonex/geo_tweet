## Geo Tweet

A prototype app to showcase MongoDB, and Twitter streaming API.

## Installation

After checkout the Rails 3 app. Edit the Twitter configuration file with your Twitter App and OAuth token 

    # modify config/twitter.yml

After bundle install, run the following to initialize the MongoDB database

	bundle install
    bundle exec rake db:mongo:init
	
## Build the data

Run the follwing rake task to connect to the Twitter Streaming API. _Ctrl-C_ or _kill -TERM_ to stop the rake task.
    
    bundle exec rake twitter:stream

The task will download the latest geo-enabled status and persist them in the MongoDB database.

Recommend to use _zeus_ to run Rails related command line.

## Search tweets

After you run the _'twitter:stream'_ rake task for a while, your local tweets data will be ready. Now you can start to do  
tweets search based on the geo coordinates you input. Start the Rails server, and then try the following url

    http://RAILS_SERVER/
	
Upon successful search, the page will return a list of tweets that are nearby the geo location of your input.


## Uninstall

If you want to uninstall database
   
	bundle exec rake db:mongo:drop

## Discussion

The app uses _tweetstream_ gem, which is an EM implementation. The app is _only_ tested with Ruby 1.9.3, MongoDB 2.4.4. 

The streaming API states that ['each account may create only one standing connection to the public endpoints'](https://dev.twitter.com/docs/streaming-apis/streams/public#Connections). So there is only one TweetStream client connected to the API. So the next question to consider is that how fast the consumer (to insert data into MongoDB) can be so that the insertion is fast enough to match the data inflow speed. One thing should be considered is that the main _tweetstream_ tweet processing block (callback) cannot be slow to slowdown the whole EM loop. 

In the _'twitter:stream'_ rake task, Ruby fiber is used to insert the tweet into the database. In the _'twitter:stream2'_ rake task, there's no Ruby fiber involded. The insertion of the tweet is merely part of the EM's callback. The second rake task is merely for the comparison of the speed. The performance of both are very close, with 1000 tweets per 24 seconds on an old Core 2 Duo 1.6GHz 2GB mem laptop. 

Fiber can be created inside the main _tweetstream_ callback (block). But it only imposes overhead by adding more execution time of initializing the Fiber each time in the callback. 

There's another approach to the problem -- to abandon the _tweetstream_ gem and use the _'em-http-request'_ directly. This gives you more control over the EM loop and the Fiber construct. But then you will face the same trick [like this](https://github.com/igrigorik/em-http-request/blob/master/examples/fibered-http.rb). The Fiber consumes the data (by persisting them into MongoDB) handed over by the async EM::HttpRequest callback. The http call and callback is handled by the main EM event loop, but the execution flow of the Fiber is still part of the EM callback, which is essentially the same approach as that of the _'twitter:stream'_ rake task. It could also run into problem because Twitter doesn't want to the client make connection to its streaming API endpoint too often.

The tweets search uses kilometer as distance unit. It searches a radius of 1km, 2km, 5km, 10km, in that order, if necessary. Any tweets geo-tagged beyond 10km is not included. The results is ordered reverse chronologically. The search radius is configurable, modify the _'config/search_criteria.yml'_ as needed.

The geo data uses Mongo _'2d'_ geo-spacial index, not the latest _'2dsphere'_ index.

Given the Twitter streaming API never sends the same status a second time, there is no unique index on the tweet/status id enforced in the database.


## Reference

* [Twitter Streaming API](https://dev.twitter.com/docs/streaming-apis)



Copyright (c) 2013 stonelonely and contributors, released under the MIT license.