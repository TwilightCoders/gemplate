# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'tmpdir'

describe Gemplate::CLI do
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

  describe '#run' do
    context 'with version command' do
      it 'displays version with version command' do
        cli = Gemplate::CLI.new(['version'])
        cli.run
        expect(output.string).to include(Gemplate::VERSION)
      end

      it 'displays version with -v flag' do
        cli = Gemplate::CLI.new(['-v'])
        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
        expect(output.string).to include(Gemplate::VERSION)
      end

      it 'displays version with --version flag' do
        cli = Gemplate::CLI.new(['--version'])
        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
        expect(output.string).to include(Gemplate::VERSION)
      end
    end

    context 'with help command' do
      it 'displays help with help command' do
        cli = Gemplate::CLI.new(['help'])
        cli.run
        expect(output.string).to include('USAGE:')
        expect(output.string).to include('gemplate new PATH')
      end

      it 'displays help with -h flag' do
        cli = Gemplate::CLI.new(['-h'])
        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
        expect(output.string).to include('USAGE:')
      end

      it 'displays help with --help flag' do
        cli = Gemplate::CLI.new(['--help'])
        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
        expect(output.string).to include('USAGE:')
      end

      it 'displays help with no arguments' do
        cli = Gemplate::CLI.new([])
        cli.run
        expect(output.string).to include('USAGE:')
      end
    end

    context 'with new command' do
      let(:gem_name) { 'test_gem' }
      let(:generator) { instance_double(Gemplate::Generator) }

      before do
        allow(Gemplate::Generator).to receive(:new).with(anything, anything).and_return(generator)
        allow(generator).to receive(:create)
      end

      it 'creates a new gem with valid name' do
        cli = Gemplate::CLI.new(['new', gem_name])
        cli.run

        expect(Gemplate::Generator).to have_received(:new).with(anything, anything)
        expect(generator).to have_received(:create)
      end

      it 'displays error when gem name is missing' do
        cli = Gemplate::CLI.new(['new'])

        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect(output.string).to include('Error: Path is required')
      end

      it 'displays error when gem name is empty' do
        cli = Gemplate::CLI.new(['new', ''])

        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect(output.string).to include('Error: Path is required')
      end

      it 'displays error when directory already exists' do
        FileUtils.mkdir_p(gem_name)
        cli = Gemplate::CLI.new(['new', gem_name])

        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect(output.string).to include("Error: Directory")
      end
    end

    context 'with unknown command' do
      it 'displays error and help for unknown command' do
        cli = Gemplate::CLI.new(['unknown'])

        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect(output.string).to include('Unknown command: unknown')
        expect(output.string).to include('USAGE:')
      end
    end
  end

  describe '#initialize' do
    it 'stores arguments and initializes options' do
      args = %w[new test_gem]
      cli = Gemplate::CLI.new(args)

      expect(cli.instance_variable_get(:@args)).to eq(args)
      expect(cli.instance_variable_get(:@options)).to eq({})
    end
  end
end
