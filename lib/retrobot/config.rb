require 'active_support/core_ext'
require 'psych'

class Retrobot
  class Config
    KEYS = %i(
      tweets_csv
      consumer_key
      consumer_secret
      access_token
      access_secret
      retro_days
      debug
      dryrun
    )

    DEFAULTS = {
      tweets_csv: GEM_ROOT.join('/tweets/tweets.csv')
      retro_days: 365,
      debug: false,
      dryrun: false
    }

    def initialize(options={})
      @options = DEFAULTS.merge(options.symbolize_keys)
    end

    def merge!(hash)
      @options.merge!(hash)
    end

    KEYS.each do |k|
      define_method(k) { @options[k] }
    end

    def retro_days
      @options[:retro_days].to_i.days
    end

    def tweets_csv
      Pathname.new(@options[:tweets_csv])
    end

    def load_yaml_file!(path)
      @options.merge! Psych.load_file(path.to_s).symbolize_keys
    end

    def load_env!
      KEYS.each do |k|
        if (v = ENV[k.to_s.upcase]) 
          @options[k] = v
        end
      end
      nil
    end
  end
end
