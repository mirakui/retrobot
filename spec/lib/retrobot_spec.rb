require 'spec_helper'
require 'timecop'
require 'retrobot'
require 'retrobot/config'

describe Retrobot do
  let(:retrobot) do
    Retrobot.new(nil).tap do |r|
      r.instance_variable_set('@config', config)
    end
  end

  let(:config) do
    Retrobot::Config.new retro_days: 365
  end

  describe '#process_line' do
    let(:line) do
      # tweet_id, in_reply_to_status_id, in_reply_to_user_id, timestamp, source,
      # text, retweeted_status_id, retweeted_status_user_id, retweeted_status_timestamp,
      ['449471248742236160','','','2014-03-28 09:01:11 +0000','<a href="http://ifttt.com" rel="nofollow">IFTTT</a>',
       '花金だーワッショーイ！テンションAGEAGEマック http://t.co/nvXD6e2rdG','','','','http://ift.tt/1d1CL0W']
    end

    context '365 days passed from the day' do
      around do |example|
        Timecop.freeze('2015-03-28 09:01:11 +0000') do
          example.run
        end
      end

      it 'should tweet' do
        expect(retrobot).to receive(:tweet).with('花金だーワッショーイ！テンションAGEAGEマック http://t.co/nvXD6e2rdG')
        expect(retrobot.process_line line).to be_true
      end

      it '"@" should be removed' do
        line[5] = '@mirakui hello'
        expect(retrobot).to receive(:tweet).with('mirakui hello')
        expect(retrobot.process_line line).to be_true
      end
    end

    context "365 days have not passed from the day" do
      it 'should not tweet' do
        Timecop.freeze('2015-03-28 09:01:10 +0000') do
          expect(retrobot).not_to receive(:tweet)
          expect(retrobot.process_line line).to be_false
        end
      end
    end
  end
end
