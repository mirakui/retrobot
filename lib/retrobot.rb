require 'retrobot/version'
require 'retrobot/config'
require 'retrobot/tweet'
require 'retrobot/tweet_filters'

require 'active_support'
require 'active_support/core_ext'
require 'twitter'
require 'retryable'
require 'logger'
require 'csv'
require 'pathname'
require 'time'
require 'optparse'
require 'cgi'

class Retrobot

  GEM_ROOT = Pathname.new('..').expand_path(__dir__)

  attr_reader :config

  def initialize(argv)
    @argv = argv
  end

  def client
    @client ||= Twitter::REST::Client.new do |config|
                  config.consumer_key = @config.consumer_key
                  config.consumer_secret = @config.consumer_secret
                  config.access_token = @config.access_token
                  config.access_token_secret = @config.access_secret
                end
  end

  def logger
    @logger ||= begin
                  l = Logger.new($stdout)
                  l.level = @config.debug ? Logger::DEBUG : Logger::INFO
                  l
                end
  end

  def csv
    @csv ||= begin
               tweets_csv = file_from_candidates(
                 @config.tweets_csv,
                 GEM_ROOT.join('tweets', 'tweets.csv'),
               )
               CSV.parse File.read(tweets_csv)
             end
  end

  def init_csv
    csv.slice! 0
    last_index = nil
    csv.each_with_index.each do |line, i|
      time = Time.parse line[3]
      if time < @config.retro_days.ago
        last_index = i
        break;
      end
    end
    csv.slice! last_index..-1 if last_index
    if csv.empty?
      logger.fatal "No data is left. Please update the tweets.csv"
      false
    else
      logger.info "Next update: \"#{csv.last[5]}\" at #{@config.retro_days.since(Time.parse(csv.last[3]))}"
      true
    end
  end

  def tweet_loop
    logger.info 'start'
    loop do
      line = csv.last
      unless line
        dying_message
        return false
      end
      if process_line(line)
        csv.pop
      end
      sleep @config.loop_interval
      logger.debug '.'
    end
    true
  end

  def dying_message
    message = "No data is left. Please update my tweets.csv. Pee.. Gaa..."
    tweet_text = if mention = @config.dying_mention_to
                   "#{mention} #{message}"
                 else
                   message
                 end
    twitter = TweetFilters::Tweet.new(self)
    twitter.tweet(tweet_text)
    logger.fatal message
  end

  def process_line(line)
    tweet = Tweet.parse_line(line)

    tweet_filters.each do |filter|
      tweet = filter.filter(tweet)
      break unless tweet
    end

    true
  rescue Twitter::Error
    logger.error "#{$!} (#{$!.class})\n  #{$@.join("\n  ")}"
    true
  rescue Retrobot::TweetFilters::RetryLater
    false
  end

  def tweet_filters
    return @tweet_filters if @tweet_filters
    @tweet_filters = []
    @tweet_filters << TweetFilters::RetroDays.new(self)
    @tweet_filters << TweetFilters::SuppressPattern.new(self) if @config.suppress_pattern
    @tweet_filters << TweetFilters::AddInReplyToUrl.new(self) if @config.add_in_reply_to_url
    @tweet_filters << TweetFilters::RemoveHashtag.new(self)   if @config.remove_hashtag
    @tweet_filters << TweetFilters::Retweet.new(self)
    @tweet_filters << TweetFilters::RemoveAtmark.new(self)
    @tweet_filters << TweetFilters::Unescape.new(self)
    @tweet_filters << TweetFilters::Tweet.new(self)
    @tweet_filters
  end

  def init_configuration
    options = parse_options()
    @config = Config.new

    config_yml = file_from_candidates(
      options[:config], './retrobot.yml',
      GEM_ROOT.join('retrobot.yml')
    )
    @config.load_yaml_file!(config_yml) if config_yml

    @config.merge!(options)

    client.current_user # for faster fail (e.g. wrong credentials given)
  end

  def parse_options
    options = {}

    opt = OptionParser.new @argv
    opt.banner = "Usage: #{$0} [OPTIONS]"
    opt.on('--debug') { options[:debug] =  true }
    opt.on('--dryrun') { options[:dryrun] = true }
    opt.on('--config file') {|v| options[:config] = v }
    opt.on('--retro-days days') {|v| options[:retro_days] = v }
    opt.on('--tweets-csv path') {|v| options[:tweets_csv] = v }
    opt.parse!

    options
  end

  def main
    init_configuration
    logger.info "Starting retrobot-#{Retrobot::VERSION}"
    exit 1 unless init_csv
    exit 1 unless tweet_loop
  end

  private

  def file_from_candidates(*candidates)
    path = candidates.find { |f| f && File.exists?(f.to_s) }
    path && path.to_s
  end
end
