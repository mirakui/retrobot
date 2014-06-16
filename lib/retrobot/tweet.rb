require 'time'

class Retrobot
  class Tweet
    attr_accessor :tweet_id, :in_reply_to_status_id, :in_reply_to_user_id, :timestamp, :source, :text,
      :retweeted_status_id, :retweeted_status_user_id, :retweeted_status_timestamp, :expanded_urls

    def self.parse_line(cols)
      t = self.new
      t.tweet_id = str_to_int_or_nil(cols[0])
      t.in_reply_to_status_id = str_to_int_or_nil(cols[1])
      t.in_reply_to_user_id = str_to_int_or_nil(cols[2])
      t.timestamp = cols[3]
      t.source = cols[4]
      t.text = cols[5]
      t.retweeted_status_id = str_to_int_or_nil(cols[6])
      t.retweeted_status_user_id = str_to_int_or_nil(cols[7])
      t.retweeted_status_timestamp = str_to_time_or_nil(cols[8])
      t.expanded_urls = cols[9..-1]
      t
    end

    def self.str_to_int_or_nil(str)
      if str.nil? || str.empty?
        nil
      else
        str.to_i
      end
    end

    def self.str_to_time_or_nil(str)
      if str.nil? || str.empty?
        nil
      else
        Time.parse(str).localtime
      end
    end
  end
end
