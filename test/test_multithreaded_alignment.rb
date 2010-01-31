require "test/unit"
require "bio"
require "thread"

module AlignmentHelper
  sequence_strings = (1..500).map {(1..5).map {Bio::Sequence::NA.new("gattaca")}}
  SEQUENCE_GROUPS = sequence_strings.map{|pair| pair.map{|sequence_string| Bio::Sequence::NA.new(sequence_string)}}
  NUMBER_THREADS = 200

  def align_group(sequence_group)
    begin
      original_alignment = Bio::Alignment.new(sequence_group)
      factory = Bio::ClustalW.new("bin/fake_clustalw")
      completed_alignment = original_alignment.do_align(factory)
    #rescue RuntimeError
      #Ignore, to ensure that tempfile itself complains about problems, rather than bioruby
    end
  end    
end

class TestAlignment < Test::Unit::TestCase
  include AlignmentHelper

  #This test already passes
  def test_alignment_works_in_single_thread
    assert_nothing_raised("Can't handle single threaded scenario") do
      SEQUENCE_GROUPS[0..10].each do |sequence_group|
        align_group(sequence_group)
      end
    end
  end

  def test_alignment_works_in_multiple_threads
    assert_nothing_raised("Can't handle multiple threaded scenario") do
      Bio::Alignment.class # Trigger lazy loading
      Bio::ClustalW::Report.class
      sequence_group_queue = Queue.new
      SEQUENCE_GROUPS.each{|sequence_group| sequence_group_queue << sequence_group}
      NUMBER_THREADS.times {sequence_group_queue << :END_OF_QUEUE}
      threads = [*1..NUMBER_THREADS].map do
        thread = Thread.new do
          while true
            sequence_group = sequence_group_queue.deq
            break if sequence_group == :END_OF_QUEUE
            align_group(sequence_group)
          end
        end
        thread
      end
      threads.each {|thread| thread.join}
    end
  end
end
