# frozen_string_literal: true

require_relative 'lib/rggen/systemrdl/version'

Gem::Specification.new do |spec|
  spec.name = 'rggen-systemrdl'
  spec.version = RgGen::SystemRDL::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.email = ['rggen@googlegroups.com']

  spec.summary = "rggen-systemrdl-#{RgGen::SystemRDL::VERSION}"
  spec.description = 'SystemRDL loader plugin for RgGen'
  spec.homepage = 'https://github.com/rggen/rggen-systemrdl'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/rggen/rggen/issues',
    'mailing_list_uri' => 'https://groups.google.com/d/forum/rggen',
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/rggen/rggen-systemrdl',
    'wiki_uri' => 'https://github.com/rggen/rggen/wiki'
  }

  spec.files =
    `git ls-files lib LICENSE README.md`.split($RS)
  spec.require_paths = ['lib']

  spec.add_dependency 'systemrdl', '>= 0.1.0'
end
