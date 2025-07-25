# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'stringio'

describe 'CLI Integration' do
  let(:temp_dir) { Dir.mktmpdir }
  let(:gem_name) { 'test_cli_gem' }
  let(:output) { StringIO.new }

  before do
    @original_dir = Dir.pwd
    Dir.chdir(temp_dir)

    # Capture output
    allow($stdout).to receive(:write) { |arg| output.write(arg) }
    allow($stdout).to receive(:puts) { |arg| output.puts(arg) }
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(temp_dir)
  end

  describe 'gemplate new command' do
    it 'creates a complete working gem' do
      cli = Gemplate::CLI.new(['new', gem_name])
      cli.run

      # Check that gem was created
      expect(Dir.exist?(gem_name)).to be true
      expect(File.exist?(File.join(gem_name, "#{gem_name}.gemspec"))).to be true
      expect(File.exist?(File.join(gem_name, 'lib', "#{gem_name}.rb"))).to be true

      # Check output
      expect(output.string).to include("Creating gem: #{gem_name}")
      expect(output.string).to include("Successfully created gem '#{gem_name}'")
    end

    it 'handles hyphenated gem names correctly' do
      hyphenated_name = 'my-test-gem'
      cli = Gemplate::CLI.new(['new', hyphenated_name])
      cli.run

      # Check files exist with correct names
      expect(File.exist?(File.join(hyphenated_name, "#{hyphenated_name}.gemspec"))).to be true
      expect(File.exist?(File.join(hyphenated_name, 'lib', "#{hyphenated_name}.rb"))).to be true

      # Check content transformations
      gemspec_content = File.read(File.join(hyphenated_name, "#{hyphenated_name}.gemspec"))
      expect(gemspec_content).to include("spec.name          = '#{hyphenated_name}'")
      expect(gemspec_content).to include('MyTestGem::VERSION')

      lib_content = File.read(File.join(hyphenated_name, 'lib', "#{hyphenated_name}.rb"))
      expect(lib_content).to include('module MyTestGem')
      expect(lib_content).not_to include('require_relative \'my_test_gem/cli\'')
    end

    it 'shows error for existing directory' do
      Dir.mkdir(gem_name)

      cli = Gemplate::CLI.new(['new', gem_name])
      expect { cli.run }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
      expect(output.string).to include("Error: Directory")
    end

    it 'shows error for missing gem name' do
      cli = Gemplate::CLI.new(['new'])
      expect { cli.run }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
      expect(output.string).to include('Error: Path is required')
    end
  end

  describe 'version command' do
    it 'shows version' do
      cli = Gemplate::CLI.new(['version'])
      cli.run
      expect(output.string.strip).to eq(Gemplate::VERSION)
    end
  end

  describe 'help command' do
    it 'shows help text' do
      cli = Gemplate::CLI.new(['help'])
      cli.run
      expect(output.string).to include('Gemplate - Ruby Gem Template Generator')
      expect(output.string).to include('USAGE:')
      expect(output.string).to include('gemplate new PATH')
    end
  end
end
