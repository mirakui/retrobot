require 'retrobot/tweet_filters/base'
require 'retryable'

class Retrobot
  module TweetFilters
    class Tweet < Base
      def initialize(retrobot)
        super
      end

      def filter(tweet)
        tweet tweet.text
      end

      private
      def tweet(text)
        logger.info "tweet: #{text}"
        return if config.dryrun
        retryable(tries: config.retry_count, sleep: config.retry_interval) do
          client.update text
        end
      end
    end
  end
end
