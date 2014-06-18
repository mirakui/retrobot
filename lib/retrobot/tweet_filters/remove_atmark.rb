require 'retrobot/tweet_filters/base'

class Retrobot
  module TweetFilters
    class RemoveAtmark < Base
      def initialize(retrobot)
        super
      end

      def filter(tweet)
        tweet.text.gsub! '@', ''
        tweet
      end
    end
  end
end
