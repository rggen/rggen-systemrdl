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

if ENV.key?('CI')
  gem 'systemrdl', github: 'taichi-ishitani/systemrdl'
else
  gem 'systemrdl', path: File.join(root, 'systemrdl')
end
