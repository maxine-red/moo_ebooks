
# frozen_string_literal: true

require_relative 'lib/moo_ebooks/version'

Gem::Specification.new do |gem|
  gem.required_ruby_version = '~> 2.3'

  gem.authors       = ['Jaiden Mispy', 'Maxine Michalski']
  gem.email         = ['maxine@furfind.net']
  gem.description   = 'A minimalistic, markov chain based, library to feed '\
                      'ebook accounts.'
  gem.summary       = 'A minimalistic ebook library'
  gem.homepage      = 'https://github.com/maxine-red/moo_ebooks'

  gem.files         = Dir['{lib,data,spec}/**/*'] + ['README.md', 'LICENSE',
                                                     'Gemfile']
  gem.name          = 'moo_ebooks'
  gem.require_paths = ['lib']
  gem.version       = Ebooks::VERSION
  gem.license       = 'MIT'

  gem.add_development_dependency 'rspec', '~> 3.6'
  gem.add_development_dependency 'rspec-mocks', '~> 3.6'
  gem.add_development_dependency 'rubocop', '~> 0.54.0'
  gem.add_development_dependency 'simplecov', '~> 0.16.1'
  gem.add_development_dependency 'yard', '~> 0.9.12'

  gem.add_runtime_dependency 'highscore', '~> 1.2'
  gem.add_runtime_dependency 'htmlentities', '~> 4.3'
end
