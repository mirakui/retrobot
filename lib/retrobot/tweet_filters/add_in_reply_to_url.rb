require 'net/https'
require 'cgi'
require 'uri'

class Retrobot
  module TweetFilters
    class AddInReplyToUrl
      TWITTER_BASE_URL = 'https://twitter.com'

      def initialize(retrobot)
        @retrobot = retrobot
      end

      def filter(tweet)
        if tweet[:in_reply_to_status_id]
          text = replace_text(tweet[:text], tweet[:in_reply_to_status_id])
          tweet.dup.merge text: text
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
                            @retrobot.logger.warn 'could not get in reply to url'
                            TWITTER_BASE_URL + path_for_redirect
                          end

        text = text[0..113] + '...' if text.length > 118
        text = text + ' ' + in_reply_to_url

        CGI.unescape_html(text.gsub('@', ''))
      end
    end
  end
end
