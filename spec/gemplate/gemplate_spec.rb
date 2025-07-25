# frozen_string_literal: true

require 'spec_helper'

describe Gemplate do
  it 'has a version number' do
    expect(Gemplate::VERSION).not_to be nil
    expect(Gemplate::VERSION).to be_a(String)
    expect(Gemplate::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  it 'has a root method that returns the gem root' do
    root = Gemplate.root
    expect(root).to be_a(Pathname)
    expect(root.to_s).to end_with('gemplate')
    expect(File.exist?(File.join(root, 'lib', 'gemplate.rb'))).to be true
  end

  it 'loads the CLI class' do
    expect(defined?(Gemplate::CLI)).to be_truthy
    expect(Gemplate::CLI).to be_a(Class)
  end

  it 'loads the Generator class' do
    expect(defined?(Gemplate::Generator)).to be_truthy
    expect(Gemplate::Generator).to be_a(Class)
  end

  it 'can create a new CLI instance' do
    cli = Gemplate::CLI.new(['help'])
    expect(cli).to be_a(Gemplate::CLI)
  end

  it 'can create a new Generator instance' do
    generator = Gemplate::Generator.new('test_gem')
    expect(generator).to be_a(Gemplate::Generator)
  end
end
