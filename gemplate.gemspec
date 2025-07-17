require_relative 'lib/gemplate/version'

Gem::Specification.new do |spec|
  spec.name          = 'gemplate'
  spec.version       = Gemplate::VERSION
  spec.authors       = ['Dale Stevens']
  spec.email         = ['dale@twilightcoders.net']

  spec.summary       = 'Ruby gem template generator with best practices.'
  spec.description   = "A CLI tool for generating Ruby gems with testing, CI, and development best practices"
  spec.homepage      = "https://github.com/TwilightCoders/gemplate"
  spec.license       = 'MIT'

  spec.metadata['allowed_push_host'].tap do |host|
    host             = 'https://rubygems.org'
  end

  spec.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE.txt', 'lib/**/*', 'bin/*']
  spec.bindir        = 'bin'
  spec.executables   = ['gemplate']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  # Template includes common development dependencies for gem development
  spec.add_development_dependency 'bundler', '>= 1.3'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry-byebug', '~> 3'

end
