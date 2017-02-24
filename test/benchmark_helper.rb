require "test_helper"
require "minitest/benchmark"
require 'fileutils'
require 'stop_watch'
require 'gruff'
include StopWatch

class BenchmarkHelper < Minitest::Benchmark
  TIMER = Hash.new.tap do |t|
    t.default_proc = proc do |hash,key|
      hash[key] = Struct.new(:ruby, :rust).new(Timer.new, Timer.new)
    end
  end

  def self.bench_range
    [20_000, 40_000, 60_000, 80_000, 100_000]
  end

  def teardown file
    super()
    if TIMER[file].rust.time? && TIMER[file].ruby.time?
      # print graph
      g = Gruff::Line.new
      g.title = File.basename(file)
      g.labels = (self.instance_exec{defined?(self.class.bench_range) ? self.class.bench_range : nil} || BenchmarkHelper.bench_range).
        each.with_index.
        reduce({}) {|h,(v,i)|
          h[i]=v;h
        }

      g.data(:ruby, TIMER[file].ruby.times.unshift(0))
      g.data(:rust, TIMER[file].rust.times.unshift(0))

      outfile = File.join(File.expand_path('..',__dir__),'doc','graph')
      FileUtils.mkdir_p outfile
      outfile = File.join(outfile, File.basename(file)[0..-3] + 'png')
      g.write( outfile )
    end
  end
end