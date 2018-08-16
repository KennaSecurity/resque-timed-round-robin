module Resque::Plugins
  module TimedRoundRobin
    def filter_busy_queues(qs)
      busy_queues = Resque::Worker.working.map { |worker| worker.job["queue"] }.compact
      Array(qs.dup).compact - busy_queues
    end

    def rotated_queues
      # only refresh queues when a slice expires
      @rtrr_queues ||= queues
      if @rtrr_queues.empty?
        @rtrr_queues = nil
        return []
      end

      @n ||= 0
      if slice_expired?
        @rtrr_queues = queues
        advance_offset
      end

      @rtrr_queues.rotate(@n)
    end

    def advance_offset
      @n = (@n + 1) % @rtrr_queues.size
    end

    DEFAULT_SLICE_LENGTH = 60
    def slice_length
      @slice_length ||= ENV.fetch("RESQUE_SLICE_LENGTH", DEFAULT_SLICE_LENGTH).to_i
    end

    def slice_expired?
      @slice_expiration ||= Time.now
      Time.now > @slice_expiration
    end

    def begin_new_queue(queue)

    end

    def queue_depth(queuename)
      busy_queues = Resque::Worker.working.map { |worker| worker.job["queue"] }.compact
      key = queue_prefix_key(queuename).to_s

      # find the queue prefix and count it.
      busy_queues.each(&:to_s).select do |busy_queue_name|
        busy_queue_name == queuename.to_s || (key && busy_queue_name.start_with?(key))
      end.size
    end

    def should_work_on_queue?(queuename)
      return true if @queues.include? '*'  # workers with QUEUES=* are special and are not subject to queue depth setting
      max = queue_depth_for(queuename)
      unless ENV["RESQUE_QUEUE_DEPTH"].nil? || ENV["RESQUE_QUEUE_DEPTH"] == ""
        max = ENV["RESQUE_QUEUE_DEPTH"].to_i
      end
      return true if max == 0 # 0 means no limiting
      cur_depth = queue_depth(queuename)
      log! "queue #{queuename} depth = #{cur_depth} max = #{max}"
      return true if cur_depth < max
      false
    end

    DEFAULT_QUEUE_DEPTH = 0

    def queue_depth_for(queuename)
      key = queue_prefix_key(queuename)
      queue_depths.fetch(key, DEFAULT_QUEUE_DEPTH)
    end

    def queue_prefix_key(queuename)
      queue_depths.keys.detect do |queue_prefix|
        partial_qn = "#{queue_prefix.to_s}_"
        queuename.to_s.start_with?(partial_qn)
      end
    end

    def queue_depths
      @queue_depths ||= Resque::Plugins::TimedRoundRobin.configuration.queue_depths
    end

    def reserve_with_round_robin
      qs = rotated_queues
      qs.each do |queue|
        log! "Checking #{queue}"
        next unless should_work_on_queue? queue
        job = reserve_job_from(queue)
        return job if job

        # Move to the next queue if current one is empty and refresh the queue list
        @n += 1
        @rtrr_queues = queues
      end

      nil
    rescue Exception => e
      log "Error reserving job: #{e.inspect}"
      log e.backtrace.join("\n")
      raise e
    end

    def reserve_job_from(queue)
      job = Resque::Job.reserve(queue)
      if job
        log! "Found job on #{queue}"

        if new_queue? queue
          @slice_expiration = Time.now + slice_length
          @queue = queue
        end
      end

      job
    end

    def new_queue?(queue)
      @queue != queue
    end

    def self.included(receiver)
      receiver.class_eval do
        alias reserve_without_round_robin reserve
        alias reserve reserve_with_round_robin
      end
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end
  end # TimedRoundRobin
end # Resque::Plugins
