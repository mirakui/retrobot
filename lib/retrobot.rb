require 'retrobot/version'
require 'retrobot/config'

require 'active_support/core_ext'
require 'twitter'
require 'dotenv'
require 'retryable'
require 'logger'
require 'csv'
require 'pathname'
require 'time'
require 'optparse'
require 'cgi'

class Retrobot
  # FIXME: make them configurable
  LOOP_INTERVAL = 3
  RETRY_INTERVAL = 3
  RETRY_COUNT = 5

  GEM_ROOT = Pathname.new('..').expand_path(__dir__)

  def client
    @client ||= begin
                  Twitter::Client.new(
                    consumer_key: @config.consumer_key,
                    consumer_secret: @config.consumer_secret,
                    oauth_token: @config.access_token,
                    oauth_token_secret: @config.access_secret
                  )
                end
  end

  def logger
    @logger ||= begin
                  l = Logger.new($stdout)
                  # FIXME: set at optparse
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
      sleep LOOP_INTERVAL
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
    retryable(tries: RETRY_COUNT, sleep: RETRY_INTERVAL) do
      client.retweet status_id
    end
  end

  def tweet(text)
    logger.info "tweet: #{text}"
    return if @config.dryrun
    retryable(tries: RETRY_COUNT, sleep: RETRY_INTERVAL) do
      client.update text
    end
  end

  def init_configuration
    options = parse_options()
    init_env(options[:env])

    @config = Config.new
    @config.load_env!

    config_yml = file_from_candidates(
      options[:config], './retrobot.yml',
      GEM_ROOT.join('retrobot.yml')
    )
    @config.load_yaml_file!(config_yml) if config_yml

    @config.merge!(options)
    # FIXME: verify crediential for faster fail
  end

  def init_env(candidate=nil)
    env_file = file_from_candidates(
      candidate, GEM_ROOT.join('.env').to_s,
      "#{Dir.pwd}/.env"
    )
    if env_file
      Dotenv.load env_file
    end
  end

  def parse_options
    options = {}

    opt = OptionParser.new ARGV
    opt.banner = "Usage: #{$0} [OPTIONS]"
    opt.on('--debug') { options[:debug] =  true }
    opt.on('--dryrun') { options[:dryrun] = true }
    opt.on('--env file') {|v| options[:env] = v }
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
