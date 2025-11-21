require "thor"
require_relative "../fontist"
require_relative "cli/class_options"

module Fontist
  class IndexCLI < Thor
    include CLI::ClassOptions

    desc "build", "Build system font index (warm/incremental build)"
    option :verbose, type: :boolean, aliases: :v,
                     desc: "Show detailed progress and statistics"
    option :output, type: :string, aliases: :o,
                    desc: "Save index to specified path (for inspection)"
    def build
      handle_class_options(options)

      stats = options[:verbose] ? Fontist::IndexStats.new : nil

      if options[:verbose]
        puts Paint["Building system font index...", :cyan, :bright]
        puts Paint["-" * 80, :cyan]
      end

      index = Fontist::SystemIndex.system_index
      index.build(verbose: options[:verbose], stats: stats)

      stats&.print_summary(verbose: options[:verbose])

      if options[:output]
        index.to_file(options[:output])
        Fontist.ui.success("Index saved to: #{options[:output]}")
      end

      Fontist.ui.success("System font index built successfully")
      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end

    desc "rebuild", "Rebuild system font index from scratch (cold build)"
    option :verbose, type: :boolean, aliases: :v,
                     desc: "Show detailed progress and statistics"
    option :output, type: :string, aliases: :o,
                    desc: "Save index to specified path (for inspection)"
    def rebuild
      handle_class_options(options)

      stats = options[:verbose] ? Fontist::IndexStats.new : nil

      if options[:verbose]
        puts Paint["Rebuilding system font index from scratch...", :cyan, :bright]
        puts Paint["-" * 80, :cyan]
      end

      index = Fontist::SystemIndex.system_index
      index.rebuild(verbose: options[:verbose], stats: stats)

      stats&.print_summary(verbose: options[:verbose])

      if options[:output]
        index.to_file(options[:output])
        Fontist.ui.success("Index saved to: #{options[:output]}")
      end

      Fontist.ui.success("System font index rebuilt successfully")
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
          last_scan: index.last_scan_time ? Time.at(index.last_scan_time).strftime("%Y-%m-%d %H:%M:%S") : "never"
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
        Fontist.ui.say("Run 'fontist index build' to create it")
      end

      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end
  end
end