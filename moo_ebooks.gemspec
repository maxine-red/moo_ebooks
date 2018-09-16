
# frozen_string_literal: true

require_relative 'lib/moo_ebooks/version'

Gem::Specification.new do |gem|
  gem.required_ruby_version = '~> 2.3'

  gem.authors       = ['Jaiden Mispy', 'Maxine Michalski']
  gem.email         = ['maxine@furfind.net']
  gem.description   = 'Markov chains for all your friends~'
  gem.summary       = 'Markov chains for all your friends~'
  gem.homepage      = ''

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'moo_ebooks'
  gem.require_paths = ['lib']
  gem.version       = Ebooks::VERSION

  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec-mocks'
  gem.add_development_dependency 'rubocop', '~> 0.54.0'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'yard'

  gem.add_runtime_dependency 'engtagger'
  gem.add_runtime_dependency 'fast-stemmer'
  gem.add_runtime_dependency 'gingerice'
  gem.add_runtime_dependency 'highscore'
  gem.add_runtime_dependency 'htmlentities'
  gem.add_runtime_dependency 'oauth'
  gem.add_runtime_dependency 'pry'
  gem.add_runtime_dependency 'twitter', '~> 6.0'
end
