require 'quiet_backtrace'
require 'test/unit'
require 'rubygems'
require 'shoulda'

class MockTestUnit
  def filter_backtrace(backtrace); end
  include QuietBacktrace::BacktraceFilter
end

class QuietBacktraceTest < Test::Unit::TestCase
  def setup
    @backtrace = [ "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit/assertions.rb:48:in `assert_block'", 
                   "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit/assertions.rb:495:in `_wrap_assertion'", 
                   "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit/assertions.rb:46:in `assert_block'", 
                   "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit/assertions.rb:313:in `flunk'", 
                   "/Users/james/Documents/railsApps/generating_station/app/controllers/photos_controller.rb:315:in `something'",
                   "/Users/james/Documents/railsApps/generating_station/vendor/plugins/quiet_stacktraces/test/quiet_stacktraces_test.rb:21:in `test_this_plugin'", 
                   "/Users/james/Documents/railsApps/generating_station/vendor/plugins/quiet_stacktraces/quiet_stacktraces_test.rb:25:in `test_this_plugin'",
                   "/Library/Ruby/Gems/1.8/gems/activerecord-1.99.0/lib/active_record/connection_adapters/mysql_adapter.rb:471:in `real_connect'",
                   "/Library/Ruby/Gems/1.8/gems/activerecord-1.99.0/lib/active_record/fixtures.rb:895:in `teardown'",
                   "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit/ui/testrunnermediator.rb:46:in `run_suite'", 
                   "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit/ui/console/testrunner.rb:67:in `start_mediator'", 
                   "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit/ui/console/testrunner.rb:41:in `start'", 
                   "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit/ui/testrunnerutilities.rb:29:in `run'", 
                   "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit/autorunner.rb:216:in `run'", 
                   "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit/autorunner.rb:12:in `run'", 
                   "/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/test/unit.rb:278", 
                   "/Users/james/Documents/railsApps/generating_station/vendor/plugins/quiet_stacktraces/test/quiet_stacktraces_test.rb:20"]
  end
  
  context "The default quiet backtrace" do
    
    setup do
      @mock = MockTestUnit.new
      @default_quiet_backtrace = @mock.filter_backtrace(@backtrace.dup)
    end

    should "silence any line from the test unit framework" do
      assert !@default_quiet_backtrace.any? { |line| line.include?('ruby') && line.include?('test/unit') }, "One or more lines from the test/unit framework are not being filtered: #{@default_quiet_backtrace}"
    end

    should "silence any line that includes ruby slash gems" do
      assert !@default_quiet_backtrace.any? { |line| line =~ /ruby\/gems/i }, "One or more lines from ruby/gems are not being filtered: #{@default_quiet_backtrace}"
    end

    should "remove in methods from the end of lines" do
      assert !@default_quiet_backtrace.any? { |line| line =~ /\:in / }, "Method name was not removed from one or more lines: #{@default_quiet_backtrace}"
    end

    should "remove rails root from the beginning of lines" do
      assert @default_quiet_backtrace.any? { |line| line == 'app/controllers/photos_controller.rb:315' }, "Rails root is not being filtered: #{@default_quiet_backtrace}"
    end
    
  end
  
  context "The quiet backtrace with complementary Rails silencers and filters" do
    
    setup do
      RAILS_ROOT = '/Users/james/Documents/railsApps/generating_station'
      Test::Unit::TestCase.backtrace_silencers << [:rails_vendor]
      Test::Unit::TestCase.backtrace_filters << [:rails_root]
      @mock = MockTestUnit.new
      @rails_quiet_backtrace = @mock.filter_backtrace(@backtrace.dup)
    end
    
    should "from RAILS_ROOT/vendor directory" do
      assert !@rails_quiet_backtrace.any? { |line| line.include?("#{RAILS_ROOT}/vendor") }, "One or more lines from RAILS_ROOT/vendor directory are not being silenced: #{@rails_quiet_backtrace}"
    end
    
    should "remove RAILS_ROOT text from the beginning of lines" do
      assert !@rails_quiet_backtrace.any? { |line| line.include?("#{RAILS_ROOT}") }, "One or more lines that include RAILS_ROOT text are not being filtered: #{@rails_quiet_backtrace}"
    end
    
  end
  
  context "Setting quiet backtrace to false" do
    
    setup do
      Test::Unit::TestCase.quiet_backtrace = false
      @mock = MockTestUnit.new
      @unfiltered_backtrace = @mock.filter_backtrace(@backtrace.dup)
    end
    
    should "keep the backtrace noisy" do
      assert_equal @backtrace, @unfiltered_backtrace, "Backtrace was silenced when it was told not to. This tool is a dictator."
    end
    
  end
  
  context "Overiding the defaults" do
    
    setup do
      Test::Unit::TestCase.backtrace_silencers = [:test_unit, :rails_vendor]
      @mock = MockTestUnit.new
      @not_filtering_gem_root = @mock.filter_backtrace(@backtrace.dup)
    end

    should "not apply a filter when it is not included in silencers" do
      assert @not_filtering_gem_root.any? { |line| line =~ /ruby\/gems/i }, "One or more lines from ruby/gems were filtered, when that filter was excluded: #{@not_filtering_gem_root}"
    end
    
  end
end