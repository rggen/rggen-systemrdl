# frozen_string_literal: true

require 'bundler/setup'
require 'rggen/devtools/spec_helper'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  RgGen::Devtools::SpecHelper.setup(config)
end

require 'rggen/systemrdl'
