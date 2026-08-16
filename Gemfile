# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in rggen-systemrdl.gemspec
gemspec

root = ENV['RGGEN_ROOT'] || File.expand_path('..', __dir__)
gemfile = File.join(root, 'rggen-devtools', 'Gemfile')
eval_gemfile(gemfile)

for_ci do
  gem_bundled 'racc'
end

path_systemrdl = File.join(root, 'systemrdl')
if ENV.key?('CI')
  gem 'systemrdl', github: 'taichi-ishitani/systemrdl'
elsif Dir.exist?(path_systemrdl)
  gem 'systemrdl', path: path_systemrdl
end
