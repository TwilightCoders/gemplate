[![Version      ](https://img.shields.io/gem/v/gemplate.svg?maxAge=2592000)](https://rubygems.org/gems/gemplate)
[![Build Status ](https://travis-ci.org/TwilightCoders/gemplate.svg)](https://travis-ci.org/TwilightCoders/gemplate)
[![Code Climate ](https://api.codeclimate.com/v1/badges/5032242cc2798697105a/maintainability)](https://codeclimate.com/github/TwilightCoders/gemplate/maintainability)
[![Test Coverage](https://codeclimate.com/github/TwilightCoders/gemplate/badges/coverage.svg)](https://codeclimate.com/github/TwilightCoders/gemplate/coverage)

# Gemplate

**Gemplate** is a Ruby gem generator that creates new gems with established best practices, testing setup, and CI configuration. Install it once and generate as many gems as you need!

## Installation

Install the gem:

```bash
gem install gemplate
```

## Usage

Create a new gem:

```bash
gemplate new my_awesome_gem
cd my_awesome_gem
bundle install
rake spec
```

## Generated Gem Features

Each generated gem includes:

- **Modern Ruby gem structure** following current conventions
- **RSpec testing framework** with sample tests
- **Rake tasks** for common development operations  
- **Bundler integration** for dependency management
- **CI/CD ready** with placeholder badge configuration
- **Git repository** with sensible .gitignore
- **MIT License** template
- **Development dependencies** pre-configured

## Commands

```bash
gemplate new GEM_NAME    # Create a new gem
gemplate version         # Show version  
gemplate help            # Show help
```

## Generated Gem Structure

```
my_awesome_gem/
├── lib/
│   ├── my_awesome_gem.rb           # Main gem file
│   └── my_awesome_gem/
│       └── version.rb              # Version specification
├── spec/
│   ├── spec_helper.rb              # RSpec configuration
│   └── my_awesome_gem/
│       └── my_awesome_gem_spec.rb  # Sample tests
├── my_awesome_gem.gemspec          # Gem specification
├── Gemfile                         # Dependencies
├── Rakefile                        # Rake tasks
├── README.md                       # Documentation
├── LICENSE.txt                     # MIT License
└── .gitignore                      # Git ignore rules
```

## Examples

```bash
# Create different types of gems
gemplate new api_client
gemplate new my-cool-gem  
gemplate new data_processor

# Each gem is ready to use immediately
cd api_client
bundle install
rake spec    # Runs tests
rake build   # Builds the gem
```

## Development

After generating a gem, customize it:

1. **Update the gemspec** with your details, description, and dependencies
2. **Implement your functionality** in the main lib file
3. **Write tests** using the included RSpec setup
4. **Update README** with usage instructions
5. **Release** when ready using `rake release`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TwilightCoders/gemplate.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

