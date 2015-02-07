require 'retryable'
require 'retrobot/tweet_filters/base'

class Retrobot
  module TweetFilters
    class Retweet < Base
      def initialize(retrobot)
        super
      end

      def filter(tweet)
        if tweet.retweeted_status_id
          if config.retweet
            retweet tweet.retweeted_status_id, tweet.text
          else
            logger.info "retweet (skipped): #{tweet.retweeted_status_id} \"#{tweet.text}\""
          end
          return nil
        else
          tweet
        end
      end

      private
      def retweet(status_id, text=nil)
        logger.info "retweet: #{status_id} \"#{text}\""
        return if config.dryrun
        Retryable.retryable(tries: config.retry_count, sleep: config.retry_interval) do
          client.retweet status_id
        end
      end
    end
  end
end
