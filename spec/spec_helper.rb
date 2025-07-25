require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter '/tmp/'

  # Add JSON formatter for qlty integration
  if ENV['CI']
    require 'simplecov_json_formatter'
    SimpleCov.formatters = [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::JSONFormatter
    ]
  end
end

require 'gemplate'
require 'pry'

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run_when_matching :focus
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Set environment variable for test runs
  config.before(:suite) do
    ENV['RSPEC_RUNNING'] = 'true'
  end

  config.after(:suite) do
    ENV.delete('RSPEC_RUNNING')
  end
end
