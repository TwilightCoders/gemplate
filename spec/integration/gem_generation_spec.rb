# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'open3'

describe 'Gem Generation Integration' do
  let(:temp_dir) { Dir.mktmpdir }
  let(:gem_name) { 'test_integration_gem' }
  let(:gem_path) { File.join(temp_dir, gem_name) }

  before do
    @original_dir = Dir.pwd
    Dir.chdir(temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(temp_dir)
  end

  describe 'complete gem generation workflow' do
    it 'generates a working gem structure' do
      # Generate the gem
      generator = Gemplate::Generator.new(gem_path, { name: gem_name })
      generator.create

      # Verify basic structure
      expect(Dir.exist?(gem_path)).to be true
      expect(File.exist?(File.join(gem_path, 'README.md'))).to be true
      expect(File.exist?(File.join(gem_path, "#{gem_name}.gemspec"))).to be true
      expect(File.exist?(File.join(gem_path, 'lib', "#{gem_name}.rb"))).to be true
      expect(File.exist?(File.join(gem_path, 'lib', gem_name, 'version.rb'))).to be true
    end

    it 'generates CI/CD configuration' do
      generator = Gemplate::Generator.new(gem_path, { name: gem_name })
      generator.create

      # Check for GitHub Actions workflows
      expect(File.exist?(File.join(gem_path, '.github', 'workflows', 'ci.yml'))).to be true

      # Check CI workflow content
      ci_content = File.read(File.join(gem_path, '.github', 'workflows', 'ci.yml'))
      expect(ci_content).to include('qltysh/qlty-action/coverage@v1')
      expect(ci_content).to include('bundle exec rspec')
      expect(ci_content).to include('bundle exec rubocop')
    end

    it 'generates quality tools configuration' do
      generator = Gemplate::Generator.new(gem_path, { name: gem_name })
      generator.create

      # Check for qlty configuration (should NOT exist as it's cleaned up)
      expect(File.exist?(File.join(gem_path, '.qlty', 'qlty.toml'))).to be false
      expect(File.exist?(File.join(gem_path, '.rubocop.yml'))).to be true

      # Verify qlty directory is cleaned up
      expect(File.exist?(File.join(gem_path, '.qlty'))).to be false
    end

    it 'generates test infrastructure' do
      generator = Gemplate::Generator.new(gem_path, { name: gem_name })
      generator.create

      # Check for test files
      expect(File.exist?(File.join(gem_path, 'spec', 'spec_helper.rb'))).to be true
      expect(File.exist?(File.join(gem_path, 'spec', gem_name, "#{gem_name}_spec.rb"))).to be true

      # Check SimpleCov configuration
      spec_helper = File.read(File.join(gem_path, 'spec', 'spec_helper.rb'))
      expect(spec_helper).to include('require \'simplecov\'')
      expect(spec_helper).to include('SimpleCov.start')
    end

    it 'properly transforms file contents' do
      generator = Gemplate::Generator.new(gem_path, { name: gem_name })
      generator.create

      # Check gemspec transformation
      gemspec_content = File.read(File.join(gem_path, "#{gem_name}.gemspec"))
      expect(gemspec_content).to include("spec.name          = '#{gem_name}'")
      expect(gemspec_content).to include('TestIntegrationGem::VERSION')
      expect(gemspec_content).to include('Your Name')
      expect(gemspec_content).to include('your.email@example.com')

      # Check main lib file transformation
      lib_content = File.read(File.join(gem_path, 'lib', "#{gem_name}.rb"))
      expect(lib_content).to include('module TestIntegrationGem')
      expect(lib_content).to include("require_relative '#{gem_name}/version'")

      # Ensure CLI-specific content is removed
      expect(lib_content).not_to include('require_relative \'test_integration_gem/cli\'')
      expect(lib_content).not_to include('require_relative \'test_integration_gem/generator\'')
    end

    it 'generates dependencies correctly' do
      generator = Gemplate::Generator.new(gem_path, { name: gem_name })
      generator.create

      gemspec_content = File.read(File.join(gem_path, "#{gem_name}.gemspec"))

      # Check for development dependencies
      expect(gemspec_content).to include('simplecov')
      expect(gemspec_content).to include('simplecov_json_formatter')
      expect(gemspec_content).to include('rubocop')
      expect(gemspec_content).to include('rspec')
      expect(gemspec_content).to include('pry-byebug')
    end

    it 'creates a valid gemspec that can be built' do
      generator = Gemplate::Generator.new(gem_path, { name: gem_name })
      generator.create

      Dir.chdir(gem_path) do
        # Try to load the gemspec
        expect {
          spec = Gem::Specification.load("#{gem_name}.gemspec")
          expect(spec.name).to eq(gem_name)
          expect(spec.authors).to eq(['Your Name'])
        }.not_to raise_error
      end
    end

    it 'excludes unwanted files' do
      generator = Gemplate::Generator.new(gem_path, { name: gem_name })
      generator.create

      # Should not copy these files to generated gem
      expect(File.exist?(File.join(gem_path, 'lib', gem_name, 'cli.rb'))).to be false
      expect(File.exist?(File.join(gem_path, 'lib', gem_name, 'generator.rb'))).to be false
      expect(File.exist?(File.join(gem_path, 'Gemfile.lock'))).to be false
      expect(File.exist?(File.join(gem_path, '.claude'))).to be false
    end
  end

  describe 'gem name variations' do
    it 'handles hyphenated names correctly' do
      hyphenated_name = 'my-awesome-gem'
      generator = Gemplate::Generator.new(hyphenated_name)
      generator.create

      gem_path = File.join(temp_dir, hyphenated_name)
      gemspec_content = File.read(File.join(gem_path, "#{hyphenated_name}.gemspec"))
      lib_content = File.read(File.join(gem_path, 'lib', "#{hyphenated_name}.rb"))

      expect(gemspec_content).to include("spec.name          = '#{hyphenated_name}'")
      expect(gemspec_content).to include('MyAwesomeGem::VERSION')
      expect(lib_content).to include('module MyAwesomeGem')
    end

    it 'handles underscored names correctly' do
      underscored_name = 'my_cool_gem'
      generator = Gemplate::Generator.new(underscored_name)
      generator.create

      gem_path = File.join(temp_dir, underscored_name)
      gemspec_content = File.read(File.join(gem_path, "#{underscored_name}.gemspec"))
      lib_content = File.read(File.join(gem_path, 'lib', "#{underscored_name}.rb"))

      expect(gemspec_content).to include("spec.name          = '#{underscored_name}'")
      expect(gemspec_content).to include('MyCoolGem::VERSION')
      expect(lib_content).to include('module MyCoolGem')
    end
  end
end
