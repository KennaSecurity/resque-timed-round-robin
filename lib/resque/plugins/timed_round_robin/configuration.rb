module Resque::Plugins
  module TimedRoundRobin
    class Configuration
      attr_accessor :paused_queues_set, :queue_depths, :queue_refresh_interval

      def initialize
        @paused_queues_set = nil
        @queue_depths = {}
        @queue_refresh_interval = 60
      end
    end
  end
end
