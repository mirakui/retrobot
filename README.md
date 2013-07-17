retrobot
=============

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
