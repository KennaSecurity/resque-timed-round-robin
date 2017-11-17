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

  describe '#queue_depth' do
    let(:worker) { Resque::Worker.new(:q1, :q2) }
    let(:worker2) { Resque::Worker.new(:q2, :q3) }

    it 'returns 0 queue depth when no jobs are running' do
      worker.register_worker
      expect(Resque::Worker.exists?(worker)).to eq(true)
      expect(worker.queue_depth(:q1)).to eq(0)
      expect(worker.queue_depth(:q2)).to eq(0)

      worker2.register_worker
      expect(Resque::Worker.exists?(worker2)).to eq(true)
      expect(worker2.queue_depth(:q2)).to eq(0)
      expect(worker2.queue_depth(:q3)).to eq(0)
    end

    it 'returns > 0 queue depth when jobs are running' do
      j1 = Resque::Job.new(:q2, SomeJob)
      j2 = Resque::Job.new(:q2, SomeJob)

      worker.register_worker
      worker.working_on(j1)
      worker2.register_worker
      worker2.working_on(j2)

      expect(Resque::Worker.exists?(worker)).to eq(true)
      expect(worker.queue_depth(:q2)).to eq(2)
      expect(worker2.queue_depth(:q2)).to eq(2)
    end
  end

  describe '#queue_depth_for' do
    let(:worker) { Resque::Worker.new(:q1, :q2) }

    it 'defaults to DEFAULT_QUEUE_DEPTH for non-customized queues' do
      expect(worker.queue_depth_for(:q1)).to eq(Resque::Plugins::TimedRoundRobin::DEFAULT_QUEUE_DEPTH)
    end

    context "when depths have been configured" do
      let(:custom_depth) { 12 }

      before do
        Resque::Plugins::TimedRoundRobin.configure do |c|
          c.queue_depths = { :q1 => custom_depth }
        end
      end

      it 'returns the customized depth' do
        expect(worker.queue_depth_for(:q1_)).to eq(custom_depth)
      end

      it 'returns the customized depth for a partial queue name match' do
        Resque::Plugins::TimedRoundRobin.configure do |c|
          c.queue_depths = { :q1 => custom_depth }
        end

        expect(worker.queue_depth_for(:q1_foobar)).to eq(custom_depth)
      end

      it 'returns the default depth for non-customized queues' do
        expect(worker.queue_depth_for(:q2)).to eq(Resque::Plugins::TimedRoundRobin::DEFAULT_QUEUE_DEPTH)
      end
    end
  end

  it "should pass lint" do
    Resque::Plugin.lint(Resque::Plugins::TimedRoundRobin)
  end
end
