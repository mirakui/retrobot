retrobot
=============
Retrobot is a twitter-bot engine which is working as [mirakui_retro](https://twitter.com/mirakui_retro).

The bot working on retrobot tweets you tweeted 365 days ago!

## Requirements
- ruby > 1.9
- [tweets.zip](https://blog.twitter.com/2012/your-twitter-archive)

## Installation

1. Create your twitter application and get cosumer key
  - https://dev.twitter.com/apps
2. Run these

```
$ git clone https://github.com/mirakui/retrobot.git
$ cd retrobot
$ bundle install
$ bundle exec get-twitter-oauth-token
(get your access token)
$ unzip ~/tweets.zip -d tweets
$ cp .env.example .env
$ vi .env
(write your oauth configurations)
```

## Running retrobot
```
$ bin/retro.rb
```

or you can run it as a daemon as follows:

```
$ bin/retro_control.rb [start|stop]
```

## License
MIT License
