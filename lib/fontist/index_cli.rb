require "thor"
require_relative "../fontist"
require_relative "cli/class_options"

module Fontist
  class IndexCLI < Thor
    include CLI::ClassOptions

    desc "rebuild", "Rebuild system font index from scratch (cold build)"
    option :verbose, type: :boolean, aliases: :v,
                     desc: "Show detailed progress and statistics"
    option :output, type: :string, aliases: :o,
                    desc: "Save index to specified path (for inspection)"
    def rebuild
      handle_class_options(options)

      # Always create stats for progress display
      stats = Fontist::IndexStats.new

      puts Paint["Rebuilding system font index from scratch...", :cyan, :bright]
      puts Paint["-" * 80, :cyan]

      # Show platform information
      os = Fontist::Utils::System.user_os
      os_name = case os
                when :macosx then "macOS"
                when :linux then "Linux"
                when :windows then "Windows"
                else os.to_s.capitalize
                end
      puts Paint["Platform: ", :white] + Paint[os_name, :yellow, :bright]
      puts

      # Show directories being scanned with spinner and counts
      puts Paint["Scanning directories:", :cyan]
      system_config = SystemFont.system_config
      templates = system_config["system"][os.to_s]["paths"]
      expanded_paths = SystemFont.expand_paths(templates)

      spinner_chars = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

      # Show spinner while scanning
      all_fonts = []
      spinner_thread = Thread.new do
        spinner_idx = 0
        loop do
          print "\r  #{Paint[spinner_chars[spinner_idx % spinner_chars.length],
                             :cyan]} Scanning font directories..."
          $stdout.flush
          spinner_idx += 1
          sleep 0.1
        end
      end

      # Actually glob to find all font files (system fonts)
      # Uses lowercase extensions since font files are normalized to
      # lowercase extensions during installation for cross-platform consistency
      expanded_paths.each do |pattern|
        all_fonts.concat(Dir.glob(pattern).select { |f| File.file?(f) })
      end

      # Add fontist-managed fonts
      # Uses case-insensitive glob patterns that work on all platforms,
      # including Linux where File::FNM_CASEFOLD is ignored
      fontist_patterns = Fontist::Utils.font_file_patterns(Fontist.fonts_path.join("**").to_s)
      fontist_fonts = fontist_patterns.flat_map { |pattern| Dir.glob(pattern) }
                                      .select { |f| File.file?(f) }
      all_fonts.concat(fontist_fonts)

      spinner_thread.kill
      print "\r#{' ' * 80}\r"

      # Group fonts by their parent directory
      fonts_by_dir = {}
      all_fonts.each do |font_path|
        dir = File.dirname(font_path)
        fonts_by_dir[dir] ||= 0
        fonts_by_dir[dir] += 1
      end

      # Sort directories and display with counts
      sorted_dirs = fonts_by_dir.keys.sort
      sorted_dirs.each do |dir|
        count = fonts_by_dir[dir]
        status = Paint["✓", :green]
        count_display = Paint[" (#{count} #{count == 1 ? 'font' : 'fonts'})",
                              :yellow]

        # Mark fontist managed directories
        is_fontist = dir.start_with?(Fontist.fonts_path.to_s)
        managed_tag = if is_fontist
                        " #{Paint['(fontist managed)', :black,
                                  :bright]}"
                      else
                        ""
                      end

        puts "  #{status} #{Paint[dir, :white]}#{count_display}#{managed_tag}"
      end

      total_font_files = all_fonts.size
      puts
      puts Paint["Total font files found: ",
                 :white] + Paint[total_font_files.to_s, :yellow, :bright]
      puts Paint["(Note: Font collections like .ttc files contain multiple fonts)",
                 :black, :bright]
      puts Paint["-" * 80, :cyan]
      puts

      # Always show progress during indexing
      index = Fontist::SystemIndex.system_index
      index.rebuild(verbose: true, stats: stats)

      if options[:verbose]
        stats.print_summary(verbose: true)
      end

      if options[:output]
        index.to_file(options[:output])
        Fontist.ui.success("Index saved to: #{options[:output]}")
      end

      # Show final summary with collection info
      total_indexed = index.fonts.size
      collection_fonts = total_indexed - total_font_files

      puts
      puts Paint["  Index file: ",
                 :white] + Paint[Fontist.system_index_path, :cyan]
      puts Paint["✓ System font index rebuilt successfully", :green, :bright]
      puts Paint["  Font files processed: ",
                 :white] + Paint[total_font_files.to_s, :yellow, :bright]
      puts Paint["  Total fonts indexed:  ",
                 :white] + Paint[total_indexed.to_s, :yellow, :bright]
      if collection_fonts.positive?
        puts Paint["  Fonts from collections: ",
                   :white] + Paint[collection_fonts.to_s,
                                   :cyan] + Paint[" (.ttc/.otc files)", :black,
                                                  :bright]
      end

      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end

    desc "path", "Show the system font index file path"
    def path
      handle_class_options(options)

      puts Fontist.system_index_path

      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end

    desc "list", "List all system fonts from the index"
    option :format, type: :string, default: "yaml",
                    desc: "Output format: yaml or json"
    option :limit, type: :numeric,
                   desc: "Limit number of fonts to display"
    def list
      handle_class_options(options)

      index = Fontist::SystemIndex.system_index
      fonts_data = index.fonts.map do |font|
        {
          path: font.path,
          family_name: font.family_name,
          full_name: font.full_name,
          subfamily: font.subfamily,
          preferred_family_name: font.preferred_family_name,
          preferred_subfamily_name: font.preferred_subfamily_name,
        }
      end

      # Apply limit if specified
      fonts_data = fonts_data.take(options[:limit]) if options[:limit]

      case options[:format].downcase
      when "json"
        require "json"
        puts JSON.pretty_generate(fonts_data)
      when "yaml"
        require "yaml"
        puts YAML.dump(fonts_data)
      else
        Fontist.ui.error("Unknown format: #{options[:format]}. Use 'yaml' or 'json'.")
        return CLI::STATUS_UNKNOWN_ERROR
      end

      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end

    desc "clear", "Delete system font index (will be rebuilt on next use)"
    def clear
      handle_class_options(options)

      index_path = Fontist.system_index_path
      if File.exist?(index_path)
        File.delete(index_path)
        Fontist.ui.success("System font index cleared: #{index_path}")
      else
        Fontist.ui.say("System font index does not exist")
      end

      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end

    desc "info", "Show system font index information"
    def info
      handle_class_options(options)

      index_path = Fontist.system_index_path

      if File.exist?(index_path)
        index = Fontist::SystemIndex.system_index
        stats = {
          path: index_path,
          size: "#{(File.size(index_path) / 1024.0).round(2)} KB",
          fonts: index.fonts&.size || 0,
          last_scan: File.mtime(index_path).strftime("%Y-%m-%d %H:%M:%S"),
        }

        puts Paint["System Font Index Information:", :cyan, :bright]
        puts Paint["-" * 80, :cyan]
        puts "  Path:       #{Paint[stats[:path], :white]}"
        puts "  Size:       #{Paint[stats[:size], :yellow]}"
        puts "  Fonts:      #{Paint[stats[:fonts], :yellow]}"
        puts "  Last scan:  #{Paint[stats[:last_scan], :green]}"
        puts Paint["-" * 80, :cyan]
      else
        Fontist.ui.say("System font index does not exist")
        Fontist.ui.say("Run 'fontist index rebuild' to create it")
      end

      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end
  end
end
