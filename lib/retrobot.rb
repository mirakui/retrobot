require 'retrobot/version'
require 'retrobot/config'

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

  def initialize(argv)
    @argv = argv
  end

  def client
    @client ||= Twitter::Client.new(
                  consumer_key: @config.consumer_key,
                  consumer_secret: @config.consumer_secret,
                  oauth_token: @config.access_token,
                  oauth_token_secret: @config.access_secret
                )
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
    csv.slice! last_index..-1
    logger.info "Next update: \"#{csv.last[5]}\" at #{@config.retro_days.since(Time.parse(csv.last[3]))}"
  end

  def tweet_loop
    logger.info 'start'
    loop do
      line = csv.last
      if process_line(line)
        csv.pop
      end
      sleep @config.loop_interval
      logger.debug '.'
    end
  end

  def process_line(line)
    tweet_id, in_reply_to_status_id, in_reply_to_user_id,
    timestamp, source, text,
    retweeted_status_id, retweeted_status_user_id, retweeted_status_timestamp,
    *expanded_urls = line

    timestamp = Time.parse(timestamp).localtime
    return false if timestamp > @config.retro_days.ago

    if retweeted_status_id.present?
      retweet retweeted_status_id.to_i, text
      return true
    end

    tweet CGI.unescape_html(text.gsub('@', ''))
    true
  rescue Twitter::Error
    logger.error "#{$!} (#{$!.class})\n  #{$@.join("\n  ")}"
    true
  end

  def retweet(status_id, text=nil)
    logger.info "retweet: #{status_id} \"#{text}\""
    return if @config.dryrun
    retryable(tries: @config.retry_count, sleep: @config.retry_interval) do
      client.retweet status_id
    end
  end

  def tweet(text)
    logger.info "tweet: #{text}"
    return if @config.dryrun
    retryable(tries: @config.retry_count, sleep: @config.retry_interval) do
      client.update text
    end
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
    init_csv
    tweet_loop
  end

  private

  def file_from_candidates(*candidates)
    path = candidates.find { |f| f && File.exists?(f.to_s) }
    path && path.to_s
  end
end
