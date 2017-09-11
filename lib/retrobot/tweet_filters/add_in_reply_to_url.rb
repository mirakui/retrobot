require 'net/https'
require 'cgi'
require 'uri'
require 'retrobot/tweet_filters/base'

class Retrobot
  module TweetFilters
    class AddInReplyToUrl < Base
      TWITTER_BASE_URL = 'https://twitter.com'.freeze

      def initialize(retrobot)
        super
      end

      def filter(tweet)
        if tweet.in_reply_to_status_id
          tweet.text = replace_text(tweet.text, tweet.in_reply_to_status_id)
          tweet
        else
          tweet
        end
      end

      private

      def http_twitter
        uri = URI.parse(TWITTER_BASE_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 3
        http.read_timeout = 3
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http
      end

      def replace_text(text, in_reply_to_status_id)
        path_for_redirect = "/%20/status/#{in_reply_to_status_id}"

        response = begin
                     http_twitter.start { |http| http.head(path_for_redirect) }
                   rescue IOError, EOFError, Errno::ECONNRESET, Errno::ETIMEDOUT, SystemCallError
                     nil
                   end

        in_reply_to_url = if response && !response['location'].blank?
                            response['location']
                          else
                            logger.warn 'could not get in reply to url'
                            TWITTER_BASE_URL + path_for_redirect
                          end

        text = text[0..113] + '...' if text.length > 118
        text = text + ' ' + in_reply_to_url

        text
      end
    end
  end
end
