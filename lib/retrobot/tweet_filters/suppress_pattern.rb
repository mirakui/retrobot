require 'retrobot/tweet_filters/base'

class Retrobot
  module TweetFilters
    class SuppressPattern < Base
      def initialize(retrobot)
        super
      end

      def filter(tweet)
        text = text tweet
        if pattern && text =~ pattern
          logger.info "Skipped by suppress_pattern: #{tweet.text}"
          nil
        else
          tweet
        end
      end

      private
      def pattern
        config.suppress_pattern ? Regexp.new(config.suppress_pattern) : nil
      end

      def text(tweet)
        tweet.retweeted_status_id ? tweet.text.sub(/^RT @.+: /, '') : tweet.text
      end
    end
  end
end
