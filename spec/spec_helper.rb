$: << File.expand_path(File.dirname(__FILE__) + "../../")

if ENV["COVERAGE"]
  require "simplecov"

  SimpleCov.start do
    add_filter "spec"
  end
end

require "chefspec"
