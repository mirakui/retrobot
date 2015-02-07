# coding: utf-8
require 'spec_helper'
require 'timecop'
require 'logger'
require 'retrobot'
require 'retrobot/config'

describe Retrobot do
  let(:retrobot) do
    Retrobot.new(nil).tap do |r|
      r.instance_variable_set('@config', config)
      r.instance_variable_set('@logger', Logger.new('/dev/null'))
    end
  end

  let(:config) do
    Retrobot::Config.new(
      retro_days: 365,
      retweet: retweet
    )
  end

  let(:client) { retrobot.client }
  let(:retweet) { false }

  describe '#process_line' do
    let(:line) do
      # tweet_id, in_reply_to_status_id, in_reply_to_user_id, timestamp, source,
      # text, retweeted_status_id, retweeted_status_user_id, retweeted_status_timestamp,
      ['449471248742236160', '', '', '2014-03-28 09:01:11 +0000', '<a href="http://ifttt.com" rel="nofollow">IFTTT</a>',
       text, retweeted_status_id, '', '', 'http://ift.tt/1d1CL0W']
    end
    let(:text) { '花金だーワッショーイ！テンションAGEAGEマック http://t.co/nvXD6e2rdG' }
    let(:retweeted_status_id) { '' }

    context '365 days passed from the day' do
      around do |example|
        Timecop.freeze('2015-03-28 09:01:11 +0000') do
          example.run
        end
      end

      it 'should tweet' do
        expect(client).to receive(:update).with('花金だーワッショーイ！テンションAGEAGEマック http://t.co/nvXD6e2rdG')
        expect(retrobot.process_line line).to be true
      end

      context 'with a text includes mention' do
        let(:text) { '@mirakui hello' }

        it '"@" should be removed' do
          expect(client).to receive(:update).with('mirakui hello')
          expect(retrobot.process_line line).to be true
        end
      end

      context 'with a line has retweeted_status_id' do
        let(:text) { 'RT @mirakui hello' }
        let(:retweeted_status_id) { '123456789' }

        context 'if retweeting enabled' do
          let(:retweet) { true }

          it 'should be retweeted' do
            expect(client).to receive(:retweet).with(123456789)
            expect(client).not_to receive(:update)
            expect(retrobot.process_line line).to be true
          end
        end

        context 'if retweeting disabled' do
          let(:retweet) { false }

          it 'should not be retweeted' do
            expect(client).not_to receive(:retweet)
            expect(client).not_to receive(:update)
            expect(retrobot.process_line line).to be true
          end
        end
      end
    end

    context "365 days have not passed from the day" do
      it 'should not tweet' do
        Timecop.freeze('2015-03-28 09:01:10 +0000') do
          expect(client).not_to receive(:update)
          expect(retrobot.process_line line).to be false
        end
      end
    end

    context "no data left" do
      before do
        allow(retrobot).to receive(:csv).and_return([]) # empty
      end

      it 'shoud exit if no data left on starting up' do
        expect(retrobot.init_csv).to be false
      end

      it 'should tweet a dying message and exit if no data left on tweet_loop' do
        expect(client).to receive(:update)
        expect(retrobot.tweet_loop).to be false
      end
    end
  end
end
