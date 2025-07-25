# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'tmpdir'

describe 'CLI Path-Based Generation' do
  let(:output) { StringIO.new }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    @original_dir = Dir.pwd
    Dir.chdir(temp_dir)

    allow($stdout).to receive(:write) { |arg| output.write(arg) }
    allow($stdout).to receive(:puts) { |arg| output.puts(arg) }
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(temp_dir)
  end

  describe 'current directory generation' do
    it 'creates gem in current directory with . argument' do
      cli = Gemplate::CLI.new(['new', '.'])
      cli.run

      # Check that files were created in current directory
      expect(File.exist?('README.md')).to be true
      expect(File.exist?("#{File.basename(temp_dir)}.gemspec")).to be true
      expect(File.exist?("lib/#{File.basename(temp_dir)}.rb")).to be true

      # Check output messages
      expect(output.string).to include("Creating gem: #{File.basename(temp_dir)}")
      expect(output.string).to include("Successfully created gem '#{File.basename(temp_dir)}'")
      expect(output.string).to include("bundle install")
      expect(output.string).to include("rake spec")
      expect(output.string).not_to include("cd ")
    end

    it 'rejects current directory if not empty' do
      # Create a file in current directory
      File.write('existing_file.txt', 'content')

      cli = Gemplate::CLI.new(['new', '.'])
      expect { cli.run }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end

      expect(output.string).to include('Error: Current directory is not empty')
      expect(output.string).to include('Found files: existing_file.txt')
    end

    it 'allows current directory with only allowed files' do
      # Create allowed files
      File.write('.gitignore', '*.gem')
      File.write('README.md', '# My Gem')
      FileUtils.mkdir_p('.git')

      cli = Gemplate::CLI.new(['new', '.'])
      cli.run

      expect(File.exist?("#{File.basename(temp_dir)}.gemspec")).to be true
      expect(output.string).to include("Successfully created gem '#{File.basename(temp_dir)}'")
    end
  end

  describe 'path-based generation' do
    it 'creates gem using path instead of gem name' do
      gem_path = 'my-awesome-gem'
      cli = Gemplate::CLI.new(['new', gem_path])
      cli.run

      # Check that files were created in specified path
      expect(File.exist?(File.join(gem_path, 'README.md'))).to be true
      expect(File.exist?(File.join(gem_path, 'my-awesome-gem.gemspec'))).to be true
      expect(File.exist?(File.join(gem_path, 'lib', 'my-awesome-gem.rb'))).to be true

      # Check output messages
      expect(output.string).to include("Creating gem: my-awesome-gem")
      expect(output.string).to include("Successfully created gem 'my-awesome-gem'")
      expect(output.string).to include("cd #{gem_path}")
    end

    it 'uses directory basename as gem name for paths' do
      gem_path = 'some/nested/my-nested-gem'
      cli = Gemplate::CLI.new(['new', gem_path])
      cli.run

      # Should use 'my-nested-gem' as the gem name
      expect(File.exist?(File.join(gem_path, 'my-nested-gem.gemspec'))).to be true
      expect(File.exist?(File.join(gem_path, 'lib', 'my-nested-gem.rb'))).to be true

      # Check module name transformation
      lib_content = File.read(File.join(gem_path, 'lib', 'my-nested-gem.rb'))
      expect(lib_content).to include('module MyNestedGem')
    end
  end

  describe '--name flag functionality' do
    it 'overrides gem name when using --name flag' do
      cli = Gemplate::CLI.new(['new', '--name', 'custom_gem_name', '.'])
      cli.run

      # Should use custom name instead of directory name
      expect(File.exist?('custom_gem_name.gemspec')).to be true
      expect(File.exist?('lib/custom_gem_name.rb')).to be true

      # Check that it uses the custom name in transformations
      lib_content = File.read('lib/custom_gem_name.rb')
      expect(lib_content).to include('module CustomGemName')
    end

    it 'uses directory name when --name flag is not provided' do
      cli = Gemplate::CLI.new(['new', '.'])
      cli.run

      # Should use directory name (temp_dir basename)
      dir_name = File.basename(temp_dir)
      expect(File.exist?("#{dir_name}.gemspec")).to be true
      expect(File.exist?("lib/#{dir_name}.rb")).to be true
    end
  end

  describe 'help text reflects new usage' do
    it 'shows PATH instead of GEM_NAME in help' do
      cli = Gemplate::CLI.new(['help'])
      cli.run

      expect(output.string).to include('gemplate new PATH')
      expect(output.string).to include('gemplate new .')
      expect(output.string).to include('Create gem in current directory')
      expect(output.string).to include('--name NAME')
    end
  end
end
