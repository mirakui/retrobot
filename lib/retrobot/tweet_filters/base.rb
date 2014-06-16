class Retrobot
  module TweetFilters
    class RetryLater < StandardError; end

    class Base
      def initialize(retrobot)
        @retrobot = retrobot
      end

      def client
        @retrobot.client
      end

      def config
        @retrobot.config
      end

      def logger
        @retrobot.logger
      end
    end
  end
end
