require 'retrobot/tweet_filters/base'

class Retrobot
  module TweetFilters
    class RemoveHashtag < Base
      def initialize(retrobot)
        super
      end

      def filter(tweet)
        if config.remove_hashtag
          tweet.text.gsub!(/(|\s)#\w+/, '')
          tweet
        else
          tweet
        end
      end
    end
  end
end
