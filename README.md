## Geo Tweet

A prototype app to showcase EventMachine, MongoDB, and Twitter streaming API.

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

After you run the _'twitter:stream'_ rake task for a while, your local tweets data will be ready. Now you can start to do search based on the geo coordinates you input. Start the Rails server, and then try the following url

    http://RAILS_SERVER/
	
Upon successful search, the page will return a list of tweets that are nearby the geo location of your input. The tweets are ordered in the order of how close they are to your search coordinates: starting from 1km radius to 2km, 5km, and then 10km in that order. The search won't return result out of the 10km radius. The radius tier can be configured in _search\_criteria.yml_. Within each radius, the result is ordered reverse chronologically.


## Uninstall

If you want to uninstall database
   
	bundle exec rake db:mongo:drop

## Test

Due to the reason that Mongoid doesn't support capped collection creation anymore, make sure you run the rake task to create the schema before test

    RAILS_ENV=test bundle exec rake db:mongo:drop db:mongo:init


## Discussion

#### Environment

The app uses _TweetStream_ gem, which is an EM implementation. The app is _only_ tested with Ruby 1.9.3, MongoDB 2.4.4. 

#### Implementation approaches

The idea is to get tweets fast and miss less tweets from the Twitter streaming data. The Twitter streaming server is the data producer, our client is the data consumer. 

The streaming API states that ['each account may create only one standing connection to the public endpoints'](https://dev.twitter.com/docs/streaming-apis/streams/public#Connections). The client doesn't have much choice but sticks to the per connection status inflow. The physical network may increase the amount of data coming in. But how fast the client gets the data is mostly capped by the server.

Now the question becomes that whether or not the consumer/client can be fast enough consumes the data sent by the server. Chasing the call sequence, you can find out that the _TweetStream_ client uses the client provided by the _em-twitter_, in which case it's a EM::Connection client connects to the server. The client is managed by EM and runs in the main EM event loop. Whenever the system tells it that there's data arriving on the port, it polls the system I/O buffer by invoking the _receive\_data_ callback. It then  buffers the data internally. Each chunk of the incoming data may not be complete, but the client decodes them into usable packets. The _TweetStream_ client then gets the data by calling the _EM::Twitter::Client#each_ iterator. This eventaully invokes the _status_ handling callback we defined when we initialized the client as a block. 

So the _status_ handling callback is executed inside the main EM event loop. It could block the event loop if it's too expensive. In the _'twitter_streaming\.rake'_ file, we include 3 different approaches to this. Case 1 (twitter:stream task) uses fiber, Case 2 (twitter:stream2 task) is the simplest by doing database insertion inside the callback. Case 3 (twitter:stream3 task) uses EM.defer to put the database insertion in the background as an asynchronous task. Case 3 is my personal favorite b/c it increases the capability of the data consumer. If the server data inflow speeds up, this can handle it well. While the other 2 cases may eventaully loose data as it all depends on how big the incoming data the system I/O buffer can hold. When you run the twitter:stream3 rake task, literally you can find out that there are 20 more connections to the MongoDB, this indirectly proves the thread-pool size of EM.defer is 20. The intersting part is that the test result shows each of these 3 approaches persists the tweet at a speed of roughly 1000 _status_ per 23 or 24 seconds. This is likely because the consumer in each case all is fast enough to consume the server data.  

Ruby Fiber can be created every time the main _TweetStream_ client callback block is invoked. But it imposes overhead of Fiber creation even though it's light weighted.

There's other approach to solve the same problem -- to abandon the _TweetStream_ gem (and thus EM::Connection#receive_data) and use the *em\-http\-request* directly. This gives you more control over the EM event loop. But then you face the same trick [like this](https://github.com/igrigorik/em-http-request/blob/master/examples/fibered-http.rb). But it could also run into problem by making connection to Twitter too often.

### The data

The geo data uses Mongo _'2d'_ geo-spacial index, not the latest _'2dsphere'_ index.

Given the Twitter streaming API never sends the same status a second time, there is no unique index on the tweet/status id enforced in the database.

Through testing, the geo coordinates [0, 0] seems to data error from Twitter. It should be handled more appropriately.


## Reference

* [Twitter Streaming API](https://dev.twitter.com/docs/streaming-apis)



Copyright (c) 2013 stonelonely and contributors, released under the MIT license.
