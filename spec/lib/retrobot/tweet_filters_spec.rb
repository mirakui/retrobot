require 'retrobot/tweet_filters'
require 'logger'

describe Retrobot::TweetFilters do
  let(:retrobot) {
    double(:retrobot, logger: Logger.new('/dev/null'))
  }

  let(:filter) { filter_class.new retrobot }

  describe 'AddInReplyToUrl#filter' do
    subject(:filter_class) { Retrobot::TweetFilters::AddInReplyToUrl }

    it 'adds in_reply_to_url' do
      # https://twitter.com/mirakui/status/419483601634205696
      tweet_before = Retrobot::Tweet.new.tap do |t|
        t.in_reply_to_status_id = 419483520973565952
        t.text = '@mirakui_retro おめでとうございます'
      end
      tweet_after = filter.filter tweet_before
      expect(tweet_after.text).to eq('@mirakui_retro おめでとうございます https://twitter.com/mirakui_retro/status/419483520973565952')
    end
  end
end
