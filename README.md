# Flattr what?

This is a Heroku [Gensen](http://gensen.herokuapp.com/) template. It uses [neo4j](http://neo4j.org) graph database and the [Flattr API](http://developers.flattr.net). The application is a super simple recommendation engine for Flattr users. It takes a look at a user and scrapes the Flattr API and tries to recommend other things to flattr.  It's written in Ruby and uses [neography](https://github.com/maxdemarzi/neography) to connect with Neo4j, [flattr](https://github.com/simon/flattr) to talk to Flattr API and the wonderful [Sinatra](https://github.com/sinatra/sinatra) web framework and [qu](https://github.com/bkeepers/qu) with [redis](http://redios.io) to scrape data in the background. There is a example of the application running over at Heroku, [Flattr what?](http://flattrwhat.herokuapp.com).

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

It takes some time to scrape the data and enter everything into Neo4j so when a request for a specific user comes in and we have never scraped that user before we send a Qu job to the background. The job connects to Flattr API and scrapes all the data and also inserts all the nodes and relations into Neo4j. The scraper will not dig especially deep into the Flattr API since we have only 1000 requests/hour before we get rate limited by the API.

```
## This is how deep we will go when we scrape data from Flattr

## First we scrape the user and all the things the user have created
user--[owner]-->thing

## Then we scape all the things the user have flattred, and all other user who have flattred the same things (other_users) and at last we look at the other_users flattrs and scrape them to.
user--[flattr]-->thing<--[flattr]--other_users--[flattr]-->other_things
```

This will give us a fairly good data to start giving recommendations. And the more we scrape the more data we will get and that means that the recommendations will become better over time.

### Query Neo4j with Cyper

When we are done with scraping the data one of the best parts comes. And that is to query Neo4j.

In the sinatra application we just ask neo4j a simple question using the Cypher query language and we will get a nice list of things that we can recommend to the user.

```ruby
get "/user/:username" do
  g = Graph.new
  user = g.get_user params[:username]
  halt 404, params[:username] if user.nil?
  r = g.cypher("START root_user = node(#{user.node_id}) MATCH root_user-[:flattr]->()<-[:flattr]-user-[:flattr]->things WHERE not(root_user-->things) RETURN things.thing_id, things.title, count(*) AS count ORDER BY count DESC LIMIT 10")
  things = r["data"]
  erb :user, :locals => { :user => user, :r => r, :things => things }
end
```

When we have all the data in Neo4j all the magic comes down to the one Cyper query.

```cypher
START root_user = node(#{user.node_id}) MATCH root_user-[:flattr]->()<-[:flattr]-user-[:flattr]->things WHERE not(root_user-->things) RETURN things.thing_id, things.title, count(*) AS count ORDER BY count DESC LIMIT 10
```

What it fetches is all the user who have flattred the same thing as `root_user`, those users flattrs that is not the same as `root_user` are returned and ordered by how many similiar things `root_user` and the `user` have flattred. And it's so beautiful and so easy!

## Questions

Both I and qzio are eager to answer questions about the application and implementation.

Twitter: [@simongate](http://twitter.com/simongate), [@qzio](http://twitter.com/qzio)   
Email: [simon@smgt.me](mailto:simon@smgt.me), [joel.hansson@gmail.com](mailto:joel.hansson@gmail.com)