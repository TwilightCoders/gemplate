
require 'pathname'
require_relative 'gemplate/version'
require_relative 'gemplate/cli'
require_relative 'gemplate/generator'

module Gemplate
  def self.root
    @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
  end
end
