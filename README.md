[![Dynamic Version Badge](<https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2FTwilightCoders%2Fgemplate%2Fmain%2FCHANGELOG.md&search=v(%5B0-9%5D%2B%5C.%5B0-9%5D%2B%5C.%5B0-9%5D%2B)&label=version&color=orange>)](https://github.com/TwilightCoders/gemplate/pkgs/rubygems/gemplate)
[![CI](https://github.com/TwilightCoders/gemplate/actions/workflows/ci.yml/badge.svg)](https://github.com/TwilightCoders/gemplate/actions/workflows/ci.yml)
[![Maintainability](https://qlty.sh/badges/853bf535-e421-4b36-b4f9-500838916f5c/maintainability.svg)](https://qlty.sh/TwilightCoders/gemplate)
[![Test Coverage](https://qlty.sh/badges/853bf535-e421-4b36-b4f9-500838916f5c/test_coverage.svg)](https://qlty.sh/gh/TwilightCoders/projects/gemplate/metrics/code?sort=coverageRating)
![GitHub License](https://img.shields.io/github/license/twilightcoders/gemplate)

# Gemplate

**Gemplate** is a Ruby gem generator that creates new gems with established best practices, testing setup, and CI configuration. Install it once and generate as many gems as you need!

## Installation

Install from GitHub Packages:

```bash
# Configure GitHub Packages as a gem source (one-time setup)
bundle config set --global https://rubygems.pkg.github.com/twilightcoders <your_github_token>

# Install the gem
gem install gemplate --source https://rubygems.pkg.github.com/twilightcoders
```

Or add to your Gemfile:

```ruby
source "https://rubygems.pkg.github.com/twilightcoders" do
  gem "gemplate"
end
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
