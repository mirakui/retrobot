retrobot
=============
Retrobot is a twitter-bot engine that working at [mirakui_retro](https://twitter.com/mirakui_retro).

Retrobot tweets a word that you've tweeted just 1 year ago!

## Requirements

- Ruby 1.9+
- Your [tweets.zip](https://blog.twitter.com/2012/your-twitter-archive)

## Installation

1. Get consumer key of Twitter API by creating application at https://dev.twitter.com/apps
2. Run the following:

```
$ git clone https://github.com/mirakui/retrobot.git
$ cd retrobot
$ bundle install
$ bundle exec get-twitter-oauth-token
(follow shown instruction)
$ unzip ~/tweets.zip -d tweets
$ cp .env.example .env
$ vi .env
(write your oauth credentials)
```

## Running retrobot

```
$ bin/retrobot
```

or you can run it as a daemon as follows:

```
$ bin/retrobotctl [start|stop]
```

## License
Copyright (c) 2013 Issei Naruta. Retrobot is released under the MIT License.
