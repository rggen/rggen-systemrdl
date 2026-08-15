# frozen_string_literal: true

require 'bundler/setup'
require 'rggen/devtools/spec_helper'
require 'support/shared_context'

require 'rggen/core'

builder = RgGen::Core::Builder.create
RgGen.builder(builder)

require 'rggen/default_register_map'
builder.plugin_manager.activate_plugin_by_name(:'rggen-default-register-map')

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  RgGen::Devtools::SpecHelper.setup(config)
end

require 'rggen/systemrdl'
builder.plugin_manager.activate_plugin_by_name(:'rggen-systemrdl')

builder.enable_all

RGGEN_SYSTEMRDL_ROOT = File.expand_path('..', __dir__)
