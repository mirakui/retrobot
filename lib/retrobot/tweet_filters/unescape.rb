require 'retrobot/tweet_filters/base'

class Retrobot
  module TweetFilters
    class Unescape < Base
      def initialize(retrobot)
        super
      end

      def filter(tweet)
        tweet.text = CGI.unescape_html tweet.text
        tweet
      end
    end
  end
end
