require "spec_helper"

describe "TimedRoundRobin" do

  before(:each) do
    Resque.redis.flushall
  end

  context "a worker" do
    it "switches queues when a slice expires" do
      5.times { Resque::Job.create(:q1, SomeJob) }
      5.times { Resque::Job.create(:q2, SomeJob) }

      worker = Resque::Worker.new(:q1, :q2)

      worker.process
      expect(Resque.size(:q1)).to eq 5
      expect(Resque.size(:q2)).to eq 4

      worker.process
      expect(Resque.size(:q1)).to eq 5
      expect(Resque.size(:q2)).to eq 3

      Timecop.travel(Time.now + 60) do
        worker.process
        expect(Resque.size(:q1)).to eq 4
        expect(Resque.size(:q2)).to eq 3
      end
    end

    it "switches from an empty queue before a slice expires" do
      5.times { Resque::Job.create(:q1, SomeJob) }
      1.times { Resque::Job.create(:q2, SomeJob) }

      worker = Resque::Worker.new(:q1, :q2)

      worker.process
      expect(Resque.size(:q1)).to eq 5
      expect(Resque.size(:q2)).to eq 0

      worker.process
      expect(Resque.size(:q1)).to eq 4
      expect(Resque.size(:q2)).to eq 0
    end
  end

  describe '#queue_depth_for' do
    it 'defaults to 0 if the DEFAULT_QUEUE_DEPTHS is not defined' do
      worker = Resque::Worker.new(:q1, :q2)
      expect(worker.queue_depth_for(:q1)).to eq(0)
    end

    it 'uses the value stored in the DEFAULT_QUEUE_DEPTHS hash if present' do
      Resque::Plugins::TimedRoundRobin::DEFAULT_QUEUE_DEPTHS = { :q1 => 2 }
      worker = Resque::Worker.new(:q1, :q2)
      expect(worker.queue_depth_for(:q1)).to eq(2)
    end
  end

  it "should pass lint" do
    Resque::Plugin.lint(Resque::Plugins::TimedRoundRobin)
  end
end
