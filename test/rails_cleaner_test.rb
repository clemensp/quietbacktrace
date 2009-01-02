class Rails; end

require File.join(File.dirname(__FILE__), 'test_helper')
require File.join(File.dirname(__FILE__), '..', 'lib', 'quietbacktrace')

class RailsCleanerTest < Test::Unit::TestCase

  ["vendor/gems", "vendor/rails", 
   "lib/mongrel", "bin/mongrel",
   "lib/passenger", "bin/passenger-spawn-server",
   "lib/rack", "script/server", 
   "rubygems/custom_require", "benchmark.rb"].each do |each|
    test "silence #{each} noise" do
      self.filter_backtrace(@backtrace.dup).each do |line| 
        assert !line.include?(each),
          "#{each} noise is not being silenced: #{line}"
      end
    end
  end

  # [].each do |each|
  #   test "filter #{each} noise" do
  #     self.filter_backtrace(@backtrace.dup).each do |line| 
  #       assert !line.include?(each),
  #         "#{each} noise is not being filtered: #{line}"
  #     end
  #   end
  # end
  
end