require 'pathname'
require 'rspec'
require 'resque-timed-round-robin'
require 'timecop'

spec_dir = File.dirname(File.expand_path(__FILE__))
REDIS_CMD = "redis-server #{spec_dir}/redis-test.conf"

puts "Starting redis for testing at localhost:9736..."
puts `cd #{spec_dir}; #{REDIS_CMD}`
Resque.redis = 'localhost:9736'

# Schedule the redis server for shutdown when tests are all finished.
at_exit do
  pid_file = Pathname.new("#{spec_dir}/redis.pid")
  if pid_file.exist?
    pid = pid_file.read.to_i
    system ("kill #{pid}") if pid != 0
  else
    puts "Unable to find pid file.  Cannot shutdown Redis"
  end
end

class SomeJob
  def self.perform(*args)
  end
end
