# frozen_string_literal: true

require "thor"
require_relative "../fontist"
require_relative "cli/class_options"
require_relative "validation"
require_relative "validator"
require "paint"

module Fontist
  class ValidateCLI < Thor
    include CLI::ClassOptions

    desc "report", "Generate validation report for all fonts"
    option :format, type: :string, default: "text",
                    desc: "Output format: text, yaml, or json"
    option :output, type: :string,
                    desc: "Save report to specified file"
    option :parallel, type: :boolean, default: true,
                      desc: "Use parallel processing"
    option :verbose, type: :boolean, aliases: :v,
                     desc: "Show detailed progress"
    def report
      handle_class_options(options)

      start_time = Time.now

      puts Paint["Generating font validation report...", :cyan, :bright]
      puts Paint["-" * 80, :cyan]

      # Validate all fonts
      validator = Validator.new
      validator.validate_all(parallel: options[:parallel],
                             verbose: options[:verbose])

      report = validator.report

      total_time = Time.now - start_time

      # Output report based on format
      case options[:format].downcase
      when "json"
        output_json_report(report, options[:output])
      when "yaml"
        output_yaml_report(report, options[:output])
      when "text"
        output_text_report(report, options[:output], total_time)
      else
        Fontist.ui.error("Unknown format: #{options[:format]}. Use 'text', 'yaml', or 'json'.")
        return CLI::STATUS_UNKNOWN_ERROR
      end

      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end

    desc "cache", "Build validation cache for fast subsequent checks"
    option :force, type: :boolean, default: false,
                   desc: "Rebuild cache even if exists and not stale"
    option :verbose, type: :boolean, aliases: :v,
                     desc: "Show detailed progress"
    def cache
      handle_class_options(options)

      cache_path = validation_cache_path

      # Check if existing cache is valid
      if !options[:force] && File.exist?(cache_path)
        existing_cache = Validator.load_cache(cache_path)
        if existing_cache && !existing_cache.stale?
          age_hours = (Time.now.to_i - existing_cache.generated_at) / 3600.0
          Fontist.ui.say("Validation cache exists and is fresh (#{age_hours.round(1)} hours old)")
          Fontist.ui.say("Use --force to rebuild")
          return CLI::STATUS_SUCCESS
        end
      end

      start_time = Time.now

      puts Paint["Building validation cache...", :cyan, :bright]
      puts Paint["-" * 80, :cyan]

      # Build cache
      validator = Validator.new
      validator.build_cache(cache_path, verbose: options[:verbose])

      total_time = Time.now - start_time

      puts
      puts Paint["-" * 80, :cyan]
      puts Paint["Cache file: ", :white] + Paint[cache_path, :cyan]
      puts Paint["Total time: ",
                 :white] + Paint["#{total_time.round(2)}s", :green, :bright]

      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end

    desc "clear", "Delete validation cache"
    def clear
      handle_class_options(options)

      cache_path = validation_cache_path

      if File.exist?(cache_path)
        File.delete(cache_path)
        Fontist.ui.success("Validation cache cleared: #{cache_path}")
      else
        Fontist.ui.say("Validation cache does not exist")
      end

      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end

    private

    def validation_cache_path
      File.join(Fontist::Utils::Cache.cache_path, "validation_cache.yml")
    end

    def output_text_report(report, output_file, total_time)
      if output_file
        File.write(output_file, format_text_report(report, total_time))
        Fontist.ui.success("Report saved to: #{output_file}")
      else
        puts format_text_report(report, total_time)
      end
    end

    def format_text_report(report, total_time)
      lines = []
      lines << ""
      lines << Paint["Validation Report Summary:", :cyan, :bright]
      lines << Paint["=" * 80, :cyan]
      lines << "  Generated:    #{Time.at(report.generated_at).strftime('%Y-%m-%d %H:%M:%S')}"
      lines << "  Platform:     #{report.platform}"
      lines << ""
      lines << Paint["Font Statistics:", :cyan, :bright]
      lines << "  Total fonts:      #{Paint[report.total_fonts.to_s, :yellow]}"
      lines << "  Valid fonts:      #{Paint[report.valid_fonts.to_s, :green]}"
      lines << "  Invalid fonts:    #{Paint[report.invalid_fonts.to_s, :red]}"
      lines << ""
      lines << Paint["Timing Statistics:", :cyan, :bright]
      lines << "  Total time:         #{Paint["#{report.total_time.round(2)}s",
                                              :green]}"
      lines << "  Avg time per font:  #{Paint["#{report.avg_time_per_font.round(4)}s",
                                              :yellow]}"
      lines << "  Min time:           #{Paint["#{report.min_time.round(4)}s",
                                              :yellow]}"
      lines << "  Max time:           #{Paint["#{report.max_time.round(4)}s",
                                              :yellow]}"
      lines << ""
      lines << "  Report generation:  #{Paint["#{total_time.round(2)}s",
                                              :cyan]}"

      if report.invalid_fonts.positive?
        lines << ""
        lines << Paint["Invalid Fonts (#{report.invalid_fonts}):", :red,
                       :bright]
        lines << Paint["-" * 80, :red]

        report.invalid_results.each do |result|
          lines << ""
          lines << Paint["  #{File.basename(result.path)}", :white, :bright]
          lines << "    Path:   #{result.path}"
          lines << Paint["    Error:  #{result.error_message}", :red]
          lines << "    Time:   #{result.time_taken}s"
        end
      end

      lines << ""
      lines << Paint["=" * 80, :cyan]
      lines.join("\n")
    end

    def output_yaml_report(report, output_file)
      yaml_content = report.to_yaml

      if output_file
        File.write(output_file, yaml_content)
        Fontist.ui.success("Report saved to: #{output_file}")
      else
        puts yaml_content
      end
    end

    def output_json_report(report, output_file)
      require "json"
      json_content = JSON.pretty_generate(report.to_hash)

      if output_file
        File.write(output_file, json_content)
        Fontist.ui.success("Report saved to: #{output_file}")
      else
        puts json_content
      end
    end
  end
end
