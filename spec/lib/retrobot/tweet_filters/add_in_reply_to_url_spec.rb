require 'active_support/core_ext/object/blank'
require 'retrobot/tweet_filters/add_in_reply_to_url'
require 'logger'

describe Retrobot::TweetFilters::AddInReplyToUrl do
  let(:retrobot) {
    double(:retrobot, logger: Logger.new('/dev/null'))
  }

  describe '#filter' do
    subject(:filter) { described_class.new(retrobot) }

    it do
      # https://twitter.com/mirakui/status/419483601634205696
      tweet_before = {
        in_reply_to_status_id: 419483520973565952,
        text: '@mirakui_retro おめでとうございます'
      }
      tweet_after = filter.filter tweet_before
      expect(tweet_after[:text]).to eq('@mirakui_retro おめでとうございます https://twitter.com/mirakui_retro/status/419483520973565952')
    end
  end
end
