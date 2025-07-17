require 'fileutils'

module Gemplate
  class Generator
    def initialize(target_path, options = {})
      @target_path = target_path
      @options = options
      @gem_name = @options[:name] || File.basename(target_path)
      @module_name = build_module_name(@gem_name)
      @snake_name = @gem_name.gsub('-', '_')
      @source_root = Gemplate.root
    end

    def create
      copy_template_structure
      rename_files
      transform_file_contents
      unless ENV['RSPEC_RUNNING']
        puts "Generated files:"
        show_created_files
      end
    end

    private

    def build_module_name(gem_name)
      parts = gem_name.split(/[-_]/)
      capitalized_parts = parts.map { |part| part[0].upcase + part[1..-1] }
      capitalized_parts.join
    end

    def copy_template_structure
      # Get list of all files/directories BEFORE creating the target directory
      # This prevents infinite recursion when the target gets created
      source_items = Dir.glob("#{@source_root}/*", File::FNM_DOTMATCH).map do |path|
        filename = File.basename(path)
        next if skip_file?(filename)

        { source: path, filename: filename }
      end.compact

      # Now create the target directory (unless it already exists)
      FileUtils.mkdir_p(@target_path) unless File.exist?(@target_path)

      # Copy the pre-determined list of files
      source_items.each do |item|
        source_path = item[:source]
        filename = item[:filename]
        dest_path = File.join(@target_path, filename)

        if File.directory?(source_path)
          copy_directory(source_path, dest_path)
        else
          FileUtils.cp(source_path, dest_path)
        end
      end
    end

    def skip_file?(filename)
      excluded_files = [
        'bin', # We'll handle this specially since it contains gemplate-specific executable
        'coverage', # Skip coverage directory from development
        '.',
        '..'
      ]

      return true if excluded_files.include?(filename)

      # Skip the target directory if we're generating in current directory to prevent infinite recursion
      file_path = File.join(@source_root, filename)
      if File.expand_path(@target_path) == File.expand_path(Dir.pwd) && 
         File.expand_path(file_path) == File.expand_path(@target_path)
        return true
      end

      # Skip any directory that looks like a generated gem
      if File.directory?(file_path)
        # Skip if it has a gemspec file that's not the main gemplate.gemspec
        gemspec_files = Dir.glob(File.join(file_path, "*.gemspec"))
        if gemspec_files.any? && !gemspec_files.include?(File.join(file_path, "gemplate.gemspec"))
          return true
        end

        # Skip if it looks like a previously generated gem directory
        if filename != 'lib' && filename != 'spec' &&
           (File.exist?(File.join(file_path, "#{filename}.gemspec")) ||
            File.exist?(File.join(file_path, "lib", filename)) ||
            File.exist?(File.join(file_path, "lib", "#{filename}.rb")))
          return true
        end
      end

      false
    end

    def copy_directory(source_dir, dest_dir)
      return if File.basename(source_dir) == '.git'

      FileUtils.mkdir_p(dest_dir)

      Dir.glob("#{source_dir}/*", File::FNM_DOTMATCH).each do |source_path|
        filename = File.basename(source_path)
        next if ['.', '..'].include?(filename)

        dest_path = File.join(dest_dir, filename)

        if File.directory?(source_path)
          copy_directory(source_path, dest_path)
        else
          FileUtils.cp(source_path, dest_path)
        end
      end
    end

    def rename_files
      # Rename gemspec file
      old_gemspec = File.join(@target_path, 'gemplate.gemspec')
      new_gemspec = File.join(@target_path, "#{@gem_name}.gemspec")
      FileUtils.mv(old_gemspec, new_gemspec) if File.exist?(old_gemspec)

      # Rename lib directory structure
      old_lib_dir = File.join(@target_path, 'lib', 'gemplate')
      new_lib_dir = File.join(@target_path, 'lib', @snake_name)

      if File.exist?(old_lib_dir)
        FileUtils.mkdir_p(File.dirname(new_lib_dir))
        FileUtils.mv(old_lib_dir, new_lib_dir)
      end

      # Rename main lib file
      old_lib_file = File.join(@target_path, 'lib', 'gemplate.rb')
      new_lib_file = File.join(@target_path, 'lib', "#{@gem_name}.rb")
      FileUtils.mv(old_lib_file, new_lib_file) if File.exist?(old_lib_file)

      # Rename spec directory structure
      old_spec_dir = File.join(@target_path, 'spec', 'gemplate')
      new_spec_dir = File.join(@target_path, 'spec', @snake_name)

      if File.exist?(old_spec_dir)
        FileUtils.mkdir_p(File.dirname(new_spec_dir))
        FileUtils.mv(old_spec_dir, new_spec_dir)
      end

      # Rename spec files
      old_spec_file = File.join(new_spec_dir, 'gemplate_spec.rb')
      new_spec_file = File.join(new_spec_dir, "#{@snake_name}_spec.rb")
      FileUtils.mv(old_spec_file, new_spec_file) if File.exist?(old_spec_file)
    end

    def transform_file_contents
      # Clean up files that shouldn't be in generated gems
      cleanup_unwanted_files

      # Remove CLI-specific files
      remove_cli_files

      # Apply global transformations to all text files
      transform_all_files

      # Create new README since the original is gemplate-specific
      create_generic_readme
    end

    def cleanup_unwanted_files
      unwanted_files = [
        "#{@target_path}/.claude",
        "#{@target_path}/CLAUDE.md",
        "#{@target_path}/.DS_Store",
        "#{@target_path}/lib/.DS_Store",
        "#{@target_path}/lib/#{@snake_name}/.DS_Store",
        "#{@target_path}/spec/.DS_Store",
        "#{@target_path}/Gemfile.lock",
        "#{@target_path}/.ruby-version",
        "#{@target_path}/.qlty",
        "#{@target_path}/coverage"
      ]

      # Also remove any .gem files
      Dir.glob("#{@target_path}/*.gem").each do |gem_file|
        unwanted_files << gem_file
      end

      unwanted_files.each do |file_path|
        if File.exist?(file_path)
          if File.directory?(file_path)
            FileUtils.rm_rf(file_path)
          else
            File.delete(file_path)
          end
        end
      end
    end

    def remove_cli_files
      cli_files = [
        File.join(@target_path, 'lib', @snake_name, 'cli.rb'),
        File.join(@target_path, 'lib', @snake_name, 'generator.rb')
      ]

      cli_files.each { |file| File.delete(file) if File.exist?(file) }
    end

    def transform_all_files
      # Find all text files to transform
      text_files = Dir.glob("#{@target_path}/**/*", File::FNM_DOTMATCH).select do |file|
        File.file?(file) && text_file?(file)
      end

      text_files.each do |file_path|
        content = File.read(file_path, encoding: 'UTF-8')

        # Apply all transformations
        content = apply_transformations(content)

        File.write(file_path, content, encoding: 'UTF-8')
      rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError, ArgumentError => e
        # Skip files with encoding issues (likely binary files misdetected as text)
        puts "Skipping file with encoding issues: #{file_path} (#{e.message})" unless ENV['RSPEC_RUNNING']
        next
      end
    end

    def text_file?(file_path)
      # Skip some specific binary file extensions
      return false if file_path.end_with?('.png', '.jpg', '.jpeg', '.gif', '.ico', '.zip', '.tar', '.gz')

      # Simple check for text files - read first few bytes
      begin
        File.open(file_path, 'rb') do |file|
          chunk = file.read(512)
          return false if chunk.nil?
          # If it contains null bytes, it's likely binary
          return false if chunk.include?("\x00")
        end
        true
      rescue
        false
      end
    end

    def apply_transformations(content)
      # Ensure content is properly encoded and handle encoding errors
      begin
        content = content.dup.force_encoding('UTF-8')
        # Test if content is valid UTF-8 by trying to encode it
        content.encode('UTF-8')
      rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
        # If encoding fails, try to scrub invalid sequences
        content = content.encode('UTF-8', invalid: :replace, undef: :replace)
      end

      # Global find and replace patterns
      transformations = {
        # Module and class names
        'Gemplate' => @module_name,

        # File paths and requires
        "require_relative 'lib/gemplate/" => "require_relative 'lib/#{@snake_name}/",
        "require_relative 'gemplate/" => "require_relative '#{@snake_name}/",
        "require 'gemplate'" => "require '#{@snake_name}'",

        # Gem specification
        "spec.name          = 'gemplate'" => "spec.name          = '#{@gem_name}'",
        "'gemplate'" => "'#{@gem_name}'",
        '"gemplate"' => "\"#{@gem_name}\"",

        # URLs and references
        'TwilightCoders/gemplate' => "yourusername/#{@gem_name}",

        # Generic placeholders for new gems
        /spec\.summary\s*=.*/ => "spec.summary       = 'Write a short summary for your gem'",
        /spec\.description\s*=.*/ => "spec.description   = 'Write a longer description for your gem'",
        /spec\.authors\s*=.*/ => "spec.authors       = ['Your Name']",
        /spec\.email\s*=.*/ => "spec.email         = ['your.email@example.com']",
        /spec\.executables\s*=.*/ => "spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }",
        /Copyright \(c\) \d+ .+/ => "Copyright (c) #{Time.now.year} Your Name"
      }

      # Remove CLI-specific requires BEFORE other transformations
      begin
        content = content.gsub(/require_relative 'gemplate\/cli'\n/, '')
        content = content.gsub(/require_relative 'gemplate\/generator'\n/, '')
      rescue Encoding::CompatibilityError, ArgumentError
        # If regex fails due to encoding, skip CLI removal
      end

      # Apply all transformations with error handling
      transformations.each do |pattern, replacement|
        begin
          content = content.gsub(pattern, replacement)
        rescue Encoding::CompatibilityError, ArgumentError
          # Skip transformation if encoding compatibility fails
          next
        end
      end

      content
    end

    def create_generic_readme
      readme_file = File.join(@target_path, 'README.md')

      new_content = <<~README
        # #{@module_name}

        Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/#{@snake_name}`. To experiment with that code, run `bin/console` for an interactive prompt.

        ## Installation

        Add this line to your application's Gemfile:

        ```ruby
        gem '#{@gem_name}'
        ```

        And then execute:

            $ bundle

        Or install it yourself as:

            $ gem install #{@gem_name}

        ## Usage

        TODO: Write usage instructions here

        ## Development

        After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

        To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

        ## Contributing

        Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/#{@gem_name}.

        ## License

        The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
      README

      File.write(readme_file, new_content)
    end

    def show_created_files
      Dir.glob("#{@target_path}/**/*", File::FNM_DOTMATCH).sort.each do |file|
        next if File.directory?(file)

        puts "  #{file}"
      end
    end
  end
end
