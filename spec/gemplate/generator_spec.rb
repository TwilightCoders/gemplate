# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'stringio'

describe Gemplate::Generator do
  let(:gem_name) { 'test_gem' }
  let(:temp_dir) { Dir.mktmpdir }
  let(:output) { StringIO.new }

  before do
    # Change to temp directory for testing
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

  describe '#initialize' do
    let(:generator) { Gemplate::Generator.new(gem_name) }

    it 'sets gem name' do
      expect(generator.instance_variable_get(:@gem_name)).to eq(gem_name)
    end

    it 'sets module name from gem name' do
      expect(generator.instance_variable_get(:@module_name)).to eq('TestGem')
    end

    it 'converts hyphens to underscores for snake_name' do
      hyphenated_generator = Gemplate::Generator.new('my-awesome-gem')
      expect(hyphenated_generator.instance_variable_get(:@snake_name)).to eq('my_awesome_gem')
      expect(hyphenated_generator.instance_variable_get(:@module_name)).to eq('MyAwesomeGem')
    end

    it 'sets source root to Gemplate root' do
      expect(generator.instance_variable_get(:@source_root)).to eq(Gemplate.root)
    end
  end

  describe '#create' do
    let(:generator) { Gemplate::Generator.new(gem_name) }

    before do
      # Mock the source root to point to a test fixture directory
      test_source = File.join(temp_dir, 'source')
      FileUtils.mkdir_p(test_source)

      # Create minimal test structure
      create_test_source_structure(test_source)

      allow(generator).to receive(:instance_variable_get).with(:@source_root).and_return(test_source)
      generator.instance_variable_set(:@source_root, test_source)
    end

    it 'creates the gem directory' do
      generator.create
      expect(Dir.exist?(gem_name)).to be true
    end

    it 'suppresses output during tests' do
      generator.create
      expect(output.string).not_to include('Generated files:')
    end

    it 'copies basic file structure' do
      generator.create

      expect(File.exist?(File.join(gem_name, 'README.md'))).to be true
      expect(File.exist?(File.join(gem_name, 'lib', "#{gem_name}.rb"))).to be true
      expect(File.exist?(File.join(gem_name, "#{gem_name}.gemspec"))).to be true
    end

    it 'transforms file contents correctly' do
      generator.create

      gemspec_content = File.read(File.join(gem_name, "#{gem_name}.gemspec"))
      expect(gemspec_content).to include("spec.name          = '#{gem_name}'")
      expect(gemspec_content).to include('TestGem::VERSION')
    end
  end

  describe 'name conversion' do
    it 'handles simple names' do
      generator = Gemplate::Generator.new('simple')
      expect(generator.instance_variable_get(:@module_name)).to eq('Simple')
      expect(generator.instance_variable_get(:@snake_name)).to eq('simple')
    end

    it 'handles hyphenated names' do
      generator = Gemplate::Generator.new('my-gem')
      expect(generator.instance_variable_get(:@module_name)).to eq('MyGem')
      expect(generator.instance_variable_get(:@snake_name)).to eq('my_gem')
    end

    it 'handles underscored names' do
      generator = Gemplate::Generator.new('my_gem')
      expect(generator.instance_variable_get(:@module_name)).to eq('MyGem')
      expect(generator.instance_variable_get(:@snake_name)).to eq('my_gem')
    end

    it 'handles mixed case names' do
      generator = Gemplate::Generator.new('MyAwesome-gem_name')
      expect(generator.instance_variable_get(:@module_name)).to eq('MyAwesomeGemName')
      expect(generator.instance_variable_get(:@snake_name)).to eq('MyAwesome_gem_name')
    end
  end

  describe 'file filtering' do
    let(:generator) { Gemplate::Generator.new(gem_name) }

    it 'skips dot files correctly' do
      skip_method = generator.method(:skip_file?)

      expect(skip_method.call('.')).to be true
      expect(skip_method.call('..')).to be true
      expect(skip_method.call('.gitignore')).to be false
      expect(skip_method.call('README.md')).to be false
    end

    it 'skips bin directory' do
      skip_method = generator.method(:skip_file?)
      expect(skip_method.call('bin')).to be true
    end

    it 'skips directories with non-gemplate gemspec files' do
      skip_method = generator.method(:skip_file?)

      # Create test directory with a different gemspec
      test_dir = File.join(temp_dir, 'some_gem')
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, 'some_gem.gemspec'), 'test')

      # Set the source root for this test
      generator.instance_variable_set(:@source_root, temp_dir)

      expect(skip_method.call('some_gem')).to be true
    end

    it 'does not skip directories with gemplate.gemspec' do
      skip_method = generator.method(:skip_file?)

      # Create test directory with gemplate.gemspec
      test_dir = File.join(temp_dir, 'lib')
      FileUtils.mkdir_p(test_dir)
      File.write(File.join(test_dir, 'gemplate.gemspec'), 'test')

      # Set the source root for this test
      generator.instance_variable_set(:@source_root, temp_dir)

      expect(skip_method.call('lib')).to be false
    end

    it 'skips directories that look like generated gems' do
      skip_method = generator.method(:skip_file?)

      # Create test directory that looks like a generated gem
      test_dir = File.join(temp_dir, 'my_gem')
      FileUtils.mkdir_p(File.join(test_dir, 'lib'))
      File.write(File.join(test_dir, 'my_gem.gemspec'), 'test')

      # Set the source root for this test
      generator.instance_variable_set(:@source_root, temp_dir)

      expect(skip_method.call('my_gem')).to be true
    end
  end

  describe 'text file detection' do
    let(:generator) { Gemplate::Generator.new(gem_name) }

    before do
      # Create test files with different content types
      File.write('text_file.txt', 'This is a text file')
      File.write('binary_file.bin', "\x00\x01\x02\x03")
      File.write('ruby_file.rb', 'puts "Hello World"')
      File.write('image.png', "\x89PNG\r\n\x1a\n")
      File.write('archive.zip', "PK\x03\x04")
    end

    it 'identifies text files correctly' do
      text_file_method = generator.method(:text_file?)

      expect(text_file_method.call('text_file.txt')).to be true
      expect(text_file_method.call('ruby_file.rb')).to be true
    end

    it 'identifies binary files correctly' do
      text_file_method = generator.method(:text_file?)

      expect(text_file_method.call('binary_file.bin')).to be false
    end

    it 'rejects known binary file extensions' do
      text_file_method = generator.method(:text_file?)

      expect(text_file_method.call('image.png')).to be false
      expect(text_file_method.call('archive.zip')).to be false
      expect(text_file_method.call('photo.jpg')).to be false
      expect(text_file_method.call('icon.ico')).to be false
    end

    it 'handles non-existent files' do
      text_file_method = generator.method(:text_file?)

      expect(text_file_method.call('non_existent.txt')).to be false
    end

    it 'handles file read errors gracefully' do
      text_file_method = generator.method(:text_file?)

      # Create a file we can't read
      File.write('test_file.txt', 'content')
      File.chmod(0000, 'test_file.txt')

      expect(text_file_method.call('test_file.txt')).to be false

      # Clean up
      File.chmod(0644, 'test_file.txt')
      File.delete('test_file.txt')
    end

    it 'handles empty files' do
      text_file_method = generator.method(:text_file?)

      File.write('empty_file.txt', '')
      expect(text_file_method.call('empty_file.txt')).to be false
    end
  end

  describe 'content transformation' do
    let(:generator) { Gemplate::Generator.new('my_awesome_gem') }

    it 'transforms module names correctly' do
      content = 'module Gemplate'
      transformed = generator.send(:apply_transformations, content)

      expect(transformed).to include('module MyAwesomeGem')
    end

    it 'transforms gemspec names correctly' do
      content = "spec.name          = 'gemplate'"
      transformed = generator.send(:apply_transformations, content)

      expect(transformed).to include("spec.name          = 'my_awesome_gem'")
    end

    it 'transforms require statements correctly' do
      content = "require 'gemplate'"
      transformed = generator.send(:apply_transformations, content)

      expect(transformed).to include("require 'my_awesome_gem'")
    end

    it 'removes CLI-specific requires' do
      content = "require_relative 'gemplate/cli'\nrequire_relative 'gemplate/generator'\n"
      transformed = generator.send(:apply_transformations, content)

      expect(transformed).not_to include("require_relative 'my_awesome_gem/cli'")
      expect(transformed).not_to include("require_relative 'my_awesome_gem/generator'")
      expect(transformed).not_to include("require_relative 'gemplate/cli'")
      expect(transformed).not_to include("require_relative 'gemplate/generator'")
    end

    it 'handles encoding issues gracefully' do
      # Test with invalid UTF-8 sequence
      invalid_content = "valid content\x80invalid"

      expect {
        generator.send(:apply_transformations, invalid_content)
      }.not_to raise_error
    end

    it 'handles encoding compatibility errors in CLI removal' do
      # Test that CLI removal handles encoding errors gracefully
      content_with_encoding_issue = "require_relative 'gemplate/cli'\n\x80"

      expect {
        generator.send(:apply_transformations, content_with_encoding_issue)
      }.not_to raise_error
    end

    it 'handles encoding compatibility errors in transformations' do
      # Test that transformations handle encoding errors gracefully
      content = "module Gemplate\n\x80invalid"

      result = generator.send(:apply_transformations, content)
      # Should not crash, content might be cleaned up
      expect(result).to be_a(String)
    end
  end

  private

  def create_test_source_structure(source_dir)
    # Create basic structure for testing
    FileUtils.mkdir_p(File.join(source_dir, 'lib', 'gemplate'))
    FileUtils.mkdir_p(File.join(source_dir, 'spec', 'gemplate'))

    # Create basic files
    File.write(File.join(source_dir, 'README.md'), '# Gemplate')
    File.write(File.join(source_dir, 'gemplate.gemspec'), <<~GEMSPEC)
      Gem::Specification.new do |spec|
        spec.name          = 'gemplate'
        spec.version       = Gemplate::VERSION
        spec.summary       = 'Test gem'
      end
    GEMSPEC

    File.write(File.join(source_dir, 'lib', 'gemplate.rb'), <<~RUBY)
      module Gemplate
        VERSION = '1.0.0'
      end
    RUBY

    File.write(File.join(source_dir, 'lib', 'gemplate', 'version.rb'), <<~RUBY)
      module Gemplate
        VERSION = '1.0.0'
      end
    RUBY

    File.write(File.join(source_dir, 'spec', 'spec_helper.rb'), "require 'gemplate'")
  end
end
