require 'resque'
require 'resque/worker'
require "resque/plugins/timed_round_robin/version"
require 'resque/plugins/timed_round_robin/configuration'
require "resque/plugins/timed_round_robin/timed_round_robin"

Resque::Worker.send(:include, Resque::Plugins::TimedRoundRobin)
