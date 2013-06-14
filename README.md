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

## Features and limitations

* The app uses _tweetstream_ gem, which is an EM implementation. The app is _only_ tested with Ruby 1.9.3, MongoDB 2.4.4. 
* The tweets search uses kilometer as distance unit. It searches a radius of 1km, 2km, 5km, 10km, in that order, if 
necessary. Any tweets geo-tagged beyond 10km is not included. The results is ordered reverse chronologically. The search
radius is configurable, modify the _'config/search_criteria.yml'_ as needed.
* The geo data uses Mongo _'2d'_ geo-spacial index, not the latest _'2dsphere'_ index.
* More rspec tests.


## Reference

* [Twitter Streaming API](https://dev.twitter.com/docs/streaming-apis)



Copyright (c) 2013 stonelonely and contributors, released under the MIT license.