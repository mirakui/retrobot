require 'retrobot/tweet'
require 'retrobot/tweet_filters'
require 'retrobot/config'
require 'logger'
require 'timecop'

describe Retrobot::TweetFilters do
  let(:retrobot) {
    double(:retrobot, logger: Logger.new('/dev/null'), config: config)
  }

  let(:filter) { filter_class.new retrobot }
  let(:config) do
    Retrobot::Config.new
  end

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

  describe 'RetroDays' do
    subject(:filter_class) { Retrobot::TweetFilters::RetroDays }
    let(:now) { Time.new(2014,01,01).localtime }
    let(:config) do
      Retrobot::Config.new retro_days: 365
    end

    it 'retrys if newer than retro_days' do
      Timecop.freeze(now) do
        tweet_before = Retrobot::Tweet.new.tap do |t|
          t.timestamp = now - 364.days
        end
        expect{ filter.filter(tweet_before) }.to raise_error(Retrobot::TweetFilters::RetryLater)
      end
    end

    it 'tweets tweet older than retro_days' do
      Timecop.freeze(now) do
        tweet_before = Retrobot::Tweet.new.tap do |t|
          t.timestamp = now - 365.days
        end
        expect(filter.filter(tweet_before)).to eq(tweet_before)
      end
    end
  end
end
