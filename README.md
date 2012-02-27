# Flattr what?

This is a Heroku [Gensen](http://gensen.herokuapp.com/) template. It uses [neo4j](http://neo4j.org) graph database and the [Flattr API](http://developers.flattr.net). The application is a super simple recommendation engine for Flattr users. It takes a look at a user and scrapes the Flattr API and tries to recommend other things to flattr.  It's written in Ruby and uses [neography](https://github.com/maxdemarzi/neography) to connect with Neo4j, [flattr](https://github.com/simon/flattr) to talk to Flattr API and the wonderful [Sinatra](https://github.com/sinatra/sinatra) web framework. There is a example of the application running over at Heroku, [Flattr what?](http://flattr-what.heroku.com).

## Flattr

Flattr is a social micro donation service that makes it easy to donate a small amount of money to your favourite content online (and offline).  More information about Flattr is available on their [homepage](http://flattr.com) and check out their [API documentation](http://developers.flattr.net). The flattr gem wrapps most of the API functions.

## Neo4j

In this application we are using Neo4j as a backend. Neo4j is a [graph database](http://en.wikipedia.org/wiki/Graph_database). That makes it really easy to build recommendation system, shortes path queries and such. In this example we will build a recommendation engine to recommend what other thing on flattr you might like.

## How it works

### Setup the code

To get hold of the source code and setup you will need Ruby and a Neo4j database runninng.

1. `git clone git://github.com/simon/flattr-what.git`
2. `cd flattr-what`
3. `bundle install`
4. `foreman start`
5. Point your browser to [http://localhost:9292](http://localhost:9292)

### Scrape data and insert to Neo4j

The application don't automatically fetch all data from Flattr instead it fetches data when a username is requested. Then the application will walk through that users flattrs and parse the things and walk the other users that have flattred that specific thing. All gets saved into the Neo4j database.

In the end it will look like this.
![Neo4j admin](https://img.skitch.com/20120227-xtafs11pdktbas282yawwqh4ct.png)

### Query Neo4j with Cyper

...

