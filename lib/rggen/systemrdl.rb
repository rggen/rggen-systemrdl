# frozen_string_literal: true

require 'systemrdl'

require_relative 'systemrdl/version'
require_relative 'systemrdl/converter/base'
require_relative 'systemrdl/converter/addrmap'
require_relative 'systemrdl/converter/regfile'
require_relative 'systemrdl/converter/reg'
require_relative 'systemrdl/converter/field'
require_relative 'systemrdl/converter/mem'
require_relative 'systemrdl/loader'

RgGen.setup_plugin :'rggen-systemrdl' do |plugin|
  plugin.version RgGen::SystemRDL::VERSION
  plugin.setup_loader :register_map, :systemrdl do |entry|
    entry.register_loaders [RgGen::SystemRDL::Loader]
  end
end
