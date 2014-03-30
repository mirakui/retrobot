[![Build Status](https://travis-ci.org/mirakui/retrobot.png?branch=master)](https://travis-ci.org/mirakui/retrobot)

retrobot
=============
Retrobot is a twitter-bot engine that working at [mirakui_retro](https://twitter.com/mirakui_retro).

Retrobot tweets a word that you've tweeted just 1 year ago!

## Requirements

- Ruby 2.0+
- Your [tweets.zip](https://blog.twitter.com/2012/your-twitter-archive)

## Installation

### Rubygems command

```
$ git clone https://github.com/mirakui/retrobot.git
$ cd retrobot
$ bundle install
```

### Using bundler

This way may be useful for deploying using capistrano or heroku.

(This way separates repository by your deployment and application itself)

```
$ bundle init
$ echo 'gem "retrobot"' >> Gemfile
$ bundle install
```

## Configuration

```
$ bundle exec get-twitter-oauth-token
(follow shown instruction to earn required credentials)

$ unzip ~/tweets.zip -d tweets
$ cp retrobot.example.yml retrobot.yml
$ vi retrobot.yml
(write your oauth credentials)
```

### Detail

Config file is set to `./retrobot.yml` from `Dir.pwd` in default.
You can give another file by using `--config` command line option.

- `consumer_key`, `consumer_secret`: Your OAuth consumer key/secret given from Twitter.
- `access_token`, `access_secret`: Your OAuth access key/secret of your Twitter account where you want to run retrobot.
- `tweets_csv`: Path to your tweets.csv (default to `./tweets/tweets.csv` in pwd)

## Running retrobot

```
$ bin/retrobot
(or, )
$ bin/retrobot -c /path/to/retrobot.yml
```

or you can run it as a daemon as follows:

```
$ bin/retrobotctl [start|stop] -- -c /path/to/retrobot.yml
```

## License
Copyright (c) 2014 Issei Naruta. Retrobot is released under the MIT License.
