require 'retrobot/tweet'
require 'retrobot/tweet_filters'
require 'retrobot/config'
require 'logger'
require 'timecop'

describe Retrobot::TweetFilters do
  let(:retrobot) do
    double(:retrobot,
           logger: Logger.new('/dev/null'),
           config: config,
           client: client)
  end

  let(:client) { double('client', retweet: nil, update: nil) }
  let(:filter) { filter_class.new retrobot }
  let(:config) do
    Retrobot::Config.new
  end

  describe 'AddInReplyToUrl#filter' do
    let(:filter_class) { Retrobot::TweetFilters::AddInReplyToUrl }

    it 'adds in_reply_to_url' do
      # https://twitter.com/mirakui/status/419483601634205696
      tweet_before = Retrobot::Tweet.new.tap do |t|
        t.in_reply_to_status_id = 419_483_520_973_565_952
        t.text = '@mirakui_retro おめでとうございます'
      end
      tweet_after = filter.filter tweet_before
      expect(tweet_after.text).to eq('@mirakui_retro おめでとうございます https://twitter.com/mirakui_retro/status/419483520973565952')
    end
  end

  describe 'RetroDays' do
    let(:filter_class) { Retrobot::TweetFilters::RetroDays }
    let(:now) { Time.new(2014, 0o1, 0o1).localtime }
    let(:config) do
      Retrobot::Config.new retro_days: 365
    end

    it 'retrys if newer than retro_days' do
      Timecop.freeze(now) do
        tweet_before = Retrobot::Tweet.new.tap do |t|
          t.timestamp = now - 364.days
        end
        expect { filter.filter(tweet_before) }.to raise_error(Retrobot::TweetFilters::RetryLater)
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

  describe 'RemoveAtmark' do
    let(:filter_class) { Retrobot::TweetFilters::RemoveAtmark }

    it 'removes atmark' do
      tweet_before = Retrobot::Tweet.new.tap do |t|
        t.text = '@mirakui_retro hello'
      end
      tweet_after = filter.filter(tweet_before)
      expect(tweet_after.text).to eq('mirakui_retro hello')
    end
  end

  describe 'RemoveHashtag' do
    let(:filter_class) { Retrobot::TweetFilters::RemoveHashtag }

    context 'config.remove_hashtag is true' do
      let(:config) { Retrobot::Config.new remove_hashtag: true }

      it 'removes hashtag' do
        tweet_before = Retrobot::Tweet.new.tap do |t|
          t.text = '@mirakui_retro hello #hashtag nospace#hashtag2'
        end
        tweet_after = filter.filter(tweet_before)
        expect(tweet_after.text).to eq('@mirakui_retro hello nospace')
      end
    end

    context 'config.remove_hashtag is false' do
      let(:config) { Retrobot::Config.new remove_hashtag: false }

      it 'dose not removes hashtag' do
        tweet_before = Retrobot::Tweet.new.tap do |t|
          t.text = '@mirakui_retro hello #hashtag nospace#hashtag2'
        end
        tweet_after = filter.filter(tweet_before)
        expect(tweet_after.text).to eq('@mirakui_retro hello #hashtag nospace#hashtag2')
      end
    end
  end

  describe 'Unescape' do
    let(:filter_class) { Retrobot::TweetFilters::Unescape }

    it 'unescapes text' do
      tweet_before = Retrobot::Tweet.new.tap do |t|
        t.text = '&gt;_&lt;'
      end
      tweet_after = filter.filter(tweet_before)
      expect(tweet_after.text).to eq('>_<')
    end
  end

  describe 'Retweet' do
    let(:filter_class) { Retrobot::TweetFilters::Retweet }

    context 'retweeted_status_id is present' do
      let(:tweet_before) do
        Retrobot::Tweet.new.tap do |t|
          t.retweeted_status_id = 123_456
        end
      end

      context 'config.retweet is true' do
        let(:config) { Retrobot::Config.new retweet: true }

        it 'retweets' do
          tweet_after = filter.filter(tweet_before)
          expect(tweet_after).to be(nil)
          expect(retrobot.client).to have_received(:retweet).with(123_456)
        end
      end

      context 'config.retweet is false' do
        let(:config) { Retrobot::Config.new retweet: false }

        it 'does not retweet' do
          tweet_after = filter.filter(tweet_before)
          expect(tweet_after).to be(nil)
          expect(retrobot.client).not_to have_received(:retweet)
        end
      end
    end

    context 'retweeted_status_id is blank' do
      let(:tweet_before) do
        Retrobot::Tweet.new.tap do |t|
          t.retweeted_status_id = nil
        end
      end
      let(:config) { Retrobot::Config.new retweet: true }

      it 'does not retweet' do
        tweet_after = filter.filter(tweet_before)
        expect(tweet_after).to eq(tweet_before)
        expect(retrobot.client).not_to have_received(:retweet)
      end
    end
  end

  describe 'Tweet' do
    let(:filter_class) { Retrobot::TweetFilters::Tweet }

    it 'tweets text' do
      tweet_before = Retrobot::Tweet.new.tap do |t|
        t.text = 'hello'
      end
      tweet_after = filter.filter(tweet_before)
      expect(tweet_after).to be(nil)
      expect(retrobot.client).to have_received(:update).with('hello')
    end
  end

  describe 'SuppressPattern' do
    let(:filter_class) { Retrobot::TweetFilters::SuppressPattern }

    context 'suppress_pattern == nil' do
      it 'does nothing' do
        tweet_before = Retrobot::Tweet.new.tap do |t|
          t.text = 'hello'
        end
        tweet_after = filter.filter(tweet_before)
        expect(tweet_after).to be(tweet_after)
      end
    end

    context 'suppress_pattern is a regexp' do
      let(:config) { Retrobot::Config.new suppress_pattern: '^@mirakui' }

      describe 'does not match text' do
        it 'does nothing' do
          tweet_before = Retrobot::Tweet.new.tap do |t|
            t.text = 'hello'
          end
          tweet_after = filter.filter(tweet_before)
          expect(tweet_after).to be(tweet_after)
        end
      end

      describe 'matches text' do
        it 'skips' do
          tweet_before = Retrobot::Tweet.new.tap do |t|
            t.text = '@mirakui hello'
          end
          tweet_after = filter.filter(tweet_before)
          expect(tweet_after).to be(nil)
        end
      end

      context 'RT text' do
        describe 'does not match text' do
          it 'skips' do
            tweet_before = Retrobot::Tweet.new.tap do |t|
              t.retweeted_status_id = 12_345
              t.text = 'RT @mirakui: hello'
            end
            tweet_after = filter.filter(tweet_before)
            expect(tweet_after).to be(tweet_after)
          end
        end

        describe 'matches text' do
          it 'skips' do
            tweet_before = Retrobot::Tweet.new.tap do |t|
              t.retweeted_status_id = 12_345
              t.text = 'RT @mirakui: @mirakui hello'
            end
            tweet_after = filter.filter(tweet_before)
            expect(tweet_after).to be(nil)
          end
        end
      end
    end
  end
end
