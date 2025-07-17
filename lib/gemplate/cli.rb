require 'optparse'
require 'fileutils'

module Gemplate
  class CLI
    def initialize(args)
      @args = args
      @options = {}
    end

    def run
      parse_options
      
      case @args.first
      when 'new'
        create_gem(@args[1])
      when 'version', '-v', '--version'
        return puts Gemplate::VERSION
      when 'help', '-h', '--help', nil
        show_help
      else
        puts "Unknown command: #{@args.first}"
        show_help
        exit 1
      end
    end

    private

    def parse_options
      OptionParser.new do |opts|
        opts.banner = "Usage: gemplate [command] [options]"
        
        opts.on("-v", "--version", "Show version") do
          puts Gemplate::VERSION
          exit
        end
        
        opts.on("-h", "--help", "Show help") do
          show_help
          exit
        end

        opts.on("-n", "--name NAME", "Override gem name (uses directory name by default)") do |name|
          @options[:name] = name
        end
      end.parse!(@args)
    end

    def create_gem(path_arg)
      if path_arg.nil? || path_arg.empty?
        puts "Error: Path is required"
        puts "Usage: gemplate new PATH"
        exit 1
      end

      # Resolve path: if not absolute, append to current directory
      target_path = File.absolute_path?(path_arg) ? path_arg : File.join(Dir.pwd, path_arg)
      target_path = File.expand_path(target_path)
      
      # Extract gem name from final directory name, or use --name override
      gem_name = @options[:name] || File.basename(target_path)
      
      # Handle current directory case (when path_arg is '.')
      if path_arg == '.'
        # Check if directory is empty (allow some common files)
        allowed_files = %w[.git .gitignore README.md LICENSE .DS_Store]
        existing_files = Dir.glob("*", File::FNM_DOTMATCH) - %w[. ..]
        unwanted_files = existing_files - allowed_files
        
        if unwanted_files.any?
          puts "Error: Current directory is not empty"
          puts "Found files: #{unwanted_files.join(', ')}"
          puts "Only these files are allowed: #{allowed_files.join(', ')}"
          exit 1
        end
      else
        # Check if target directory already exists
        if File.exist?(target_path)
          puts "Error: Directory '#{target_path}' already exists"
          exit 1
        end
      end
      
      puts "Creating gem: #{gem_name}"
      puts "Target path: #{target_path}"
      
      Generator.new(target_path, @options).create
      
      puts ""
      puts "Successfully created gem '#{gem_name}'"
      puts ""
      
      if path_arg == '.'
        puts "Next steps:"
        puts "  bundle install"
        puts "  rake spec"
      else
        puts "Next steps:"
        puts "  cd #{File.basename(path_arg)}"
        puts "  bundle install"
        puts "  rake spec"
      end
    end

    def show_help
      puts <<~HELP
        Gemplate - Ruby Gem Template Generator

        USAGE:
          gemplate new PATH [OPTIONS]  Create a new gem from template
          gemplate version             Show version
          gemplate help                Show this help

        OPTIONS:
          -n, --name NAME              Override gem name (uses directory name by default)
          -h, --help                   Show this help
          -v, --version                Show version

        EXAMPLES:
          gemplate new my_awesome_gem           Create ./my_awesome_gem/ directory
          gemplate new .                        Create gem in current directory
          gemplate new --name my_gem .          Create gem named 'my_gem' in current directory
          gemplate new nested/path/my_gem       Create nested/path/my_gem/ directory

        The generated gem will include:
          • Modern Ruby gem structure
          • RSpec testing framework
          • Rake tasks for development
          • Bundler integration
          • CI/CD ready configuration

        NOTE: Gem name is always inferred from the final directory name unless overridden with --name
      HELP
    end
  end
end
