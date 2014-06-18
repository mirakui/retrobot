require 'active_support'
require 'active_support/core_ext'
require 'retrobot/tweet_filters/base'

class Retrobot
  module TweetFilters
    class RetroDays < Base
      def initialize(retrobot)
        super
      end

      def filter(tweet)
        if tweet.timestamp > config.retro_days.ago
          raise RetryLater
        else
          tweet
        end
      end
    end
  end
end
