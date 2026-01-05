require "plist"
require "nokogiri"
require "paint"
require "fontist/import/create_formula"
require_relative "../macos/catalog/catalog_manager"
require_relative "../macos_import_source"
require_relative "../google_import_source"
require_relative "../sil_import_source"

module Fontist
  module Import
    class Macos
      HOMEPAGE = "https://support.apple.com/en-om/HT211240#document".freeze

      def initialize(catalog_path, formulas_dir: nil, font_name: nil, force: false, verbose: false, import_cache: nil)
        @catalog_path = catalog_path
        @custom_formulas_dir = formulas_dir
        @font_name_filter = font_name
        @force = force
        @verbose = verbose
        @import_cache = import_cache
        @success_count = 0
        @failure_count = 0
        @skipped_count = 0
        @overwritten_count = 0
        @total_bytes = 0
        @failures = []  # Track {name, reason} for each failure
        @parser = Fontist::Macos::Catalog::CatalogManager.parser_for(@catalog_path)
      end

      def call
        print_header

        assets = filter_assets(@parser.assets)

        # Exit early if no fonts match filter
        if assets.empty?
          Fontist.ui.say("")
          Fontist.ui.say(Paint["No fonts to import. Exiting.", :yellow])
          return
        end

        if @font_name_filter
          Fontist.ui.say("🔍 Filter: #{Paint[@font_name_filter, :cyan, :bright]}")
        end
        Fontist.ui.say("📦 Found #{Paint[assets.size, :yellow, :bright]} font packages in catalog")
        Fontist.ui.say("📁 Saving formulas to: #{Paint[formula_dir(@parser.framework_version), :cyan]}")
        Fontist.ui.say("🔄 Mode: #{@force ? Paint['Force (overwrite existing)', :red, :bright] : Paint['Normal (skip existing)', :green]}")
        Fontist.ui.say("")

        assets.each_with_index do |asset, index|
          process_asset(asset, index + 1, assets.size)
        end

        print_summary(assets.size)
      end

      private

      def filter_assets(assets)
        return assets unless @font_name_filter

        filtered = assets.select do |asset|
          family_name = asset.primary_family_name || ""
          family_name.downcase.include?(@font_name_filter.downcase)
        end

        if filtered.empty?
          Fontist.ui.error("No fonts matching '#{@font_name_filter}' found in catalog")
        end

        filtered
      end

      def print_header
        Fontist.ui.say("")
        Fontist.ui.say(Paint["═" * 80, :cyan])
        Fontist.ui.say(Paint["  🍎 macOS Supplementary Fonts Import", :cyan, :bright])
        Fontist.ui.say(Paint["═" * 80, :cyan])
        Fontist.ui.say("")

        if @verbose
          Fontist.ui.say("📦 Import cache: #{Paint[Fontist.import_cache_path, :white]}")
          Fontist.ui.say("📁 Formula output: #{Paint[Fontist.formulas_path, :white]}")
          Fontist.ui.say("")
        end
      end

      def process_asset(asset, current, total)
        return if asset.fonts.empty?

        family_name = asset.primary_family_name || "Unknown"
        fonts_count = asset.fonts.size

        # Progress indicator
        progress = "(#{current}/#{total})"
        percentage = ((current.to_f / total) * 100).round(1)

        Fontist.ui.say("#{Paint[progress, :white]} #{Paint["#{percentage}%", :yellow]} | #{Paint[family_name, :cyan, :bright]} #{Paint["(#{fonts_count} font#{fonts_count > 1 ? 's' : ''})", :black, :bright]}")

        start_time = Time.now

        # Create import source from asset
        import_source = asset.to_import_source

        path = Fontist::Import::CreateFormula.new(
          asset.download_url,
          platforms: platforms(asset.framework_version),
          homepage: homepage,
          requires_license_agreement: license,
          formula_dir: formula_dir(asset.framework_version),
          keep_existing: !@force,
          import_source: import_source,
          verbose: @verbose,
          import_cache: @import_cache,
          name: family_name,
        ).call

        elapsed = Time.now - start_time
        formula_name = File.basename(path)

        # Check if the file was just created (modified within last 2 seconds) or already existed
        file_modified_time = File.mtime(path)
        was_just_created = (Time.now - file_modified_time) < 2

        if was_just_created
          # Read the generated formula to show fonts/styles
          show_formula_fonts(path)

          @success_count += 1
          Fontist.ui.say("  #{Paint['✓', :green]} Formula created: #{Paint[formula_name, :white]} #{Paint["(#{elapsed.round(2)}s)", :black, :bright]}")
        else
          # File already existed and was skipped by keep_existing check
          @skipped_count += 1
          Fontist.ui.say("  #{Paint['⊝', :yellow]} Skipped (already exists): #{Paint[formula_name, :black, :bright]}")
          Fontist.ui.say("    #{Paint['ℹ', :blue]} Use #{Paint['--force', :cyan]} to overwrite existing formulas")
        end
      rescue Fontist::Errors::FontNotFoundError => e
        @failure_count += 1
        # Extract parsing errors if available
        parsing_errors = e.has_parsing_errors? ? e.parsing_errors : []
        @failures << {
          name: family_name,
          error: e.message,
          parsing_errors: parsing_errors,
          url: asset.download_url,
          cache_path: find_cached_file(asset.download_url)
        }
        Fontist.ui.say("  #{Paint['✗', :red]} Failed: No fonts found in archive")
      rescue StandardError => e
        @failure_count += 1
        error_msg = e.message.length > 60 ? "#{e.message[0..60]}..." : e.message
        @failures << {
          name: family_name,
          error: error_msg,
          parsing_errors: [],
          url: asset.download_url,
          cache_path: find_cached_file(asset.download_url)
        }
        Fontist.ui.say("  #{Paint['✗', :red]} Failed: #{Paint[error_msg, :red]}")
      end

      def versioned_formula_path(asset, family_name)
        # Try to predict the formula filename based on family name and asset_id
        # This creates unique filenames to avoid collisions
        normalized_name = Fontist::Import.normalize_filename(family_name)
        asset_key = asset.asset_id&.downcase || "unknown"
        formula_dir(asset.framework_version).join("#{normalized_name}_#{asset_key}.yml")
      rescue StandardError
        nil
      end

      def show_formula_fonts(formula_path)
        formula = Fontist::Formula.from_file(formula_path)
        return unless formula && formula.fonts

        formula.fonts.each do |font|
          next unless font.styles && !font.styles.empty?

          # Group styles info - safely handle nil values
          styles = font.styles.map do |style|
            parts = []
            parts << style.type if style.respond_to?(:type) && style.type
            parts << "(#{style.post_script_name})" if style.respond_to?(:post_script_name) && style.post_script_name
            parts.join(" ")
          end.reject(&:empty?)

          next if styles.empty?

          styles_display = styles.take(3).join(", ")
          styles_display += ", ..." if styles.size > 3

          font_name = font.respond_to?(:name) && font.name ? font.name : "Unknown"
          Fontist.ui.say("    #{Paint['→', :blue]} #{Paint[font_name, :white]}: #{Paint[styles_display, :black, :bright]}")
        end
      rescue TypeError, NoMethodError, ArgumentError => e
        # These errors happen when YAML contains nil values in string fields
        # or when the schema doesn't match - just skip display
        Fontist.ui.debug("Could not read formula fonts (schema mismatch or nil values): #{e.message}")
      rescue StandardError => e
        # Other errors should be visible in debug mode
        Fontist.ui.debug("Could not read formula fonts: #{e.message}")
      end

      def print_summary(total)
        Fontist.ui.say("")
        Fontist.ui.say(Paint["═" * 80, :cyan])
        Fontist.ui.say(Paint["  📊 Import Summary", :cyan, :bright])
        Fontist.ui.say(Paint["═" * 80, :cyan])
        Fontist.ui.say("")

        success_rate = (@success_count.to_f / total * 100).round(1)
        skip_rate = (@skipped_count.to_f / total * 100).round(1) if @skipped_count > 0

        Fontist.ui.say("  Total packages:     #{Paint[total.to_s, :white]}")
        Fontist.ui.say("  #{Paint['✓', :green]} Successful:     #{Paint[@success_count.to_s, :green, :bright]} #{Paint["(#{success_rate}%)", :green]}")

        if @skipped_count > 0
          Fontist.ui.say("  #{Paint['⊝', :yellow]} Skipped:        #{Paint[@skipped_count.to_s, :yellow]} #{Paint["(#{skip_rate}%)", :yellow]} #{Paint['(already exists)', :black, :bright]}")
        end

        if @overwritten_count > 0
          Fontist.ui.say("  #{Paint['⚠', :yellow]} Overwritten:    #{Paint[@overwritten_count.to_s, :yellow]}")
        end

        if @failure_count > 0
          Fontist.ui.say("  #{Paint['✗', :red]} Failed:         #{Paint[@failure_count.to_s, :red]}")
        end

        if @failure_count > 0
          Fontist.ui.say("")
          Fontist.ui.say("  #{Paint['ℹ', :blue]}  Note: Failures may be due to download issues or unsupported font formats.")
        end

        if @skipped_count > 0 && !@force
          Fontist.ui.say("")
          Fontist.ui.say("  #{Paint['💡 Tip:', :cyan]} Use #{Paint['--force', :cyan, :bright]} to overwrite existing formulas:")
          Fontist.ui.say("    fontist import macos --plist=<path> --force")
        end

        Fontist.ui.say("")

        if @success_count > (total * 0.5)
          Fontist.ui.say(Paint["  🎉 Great success! #{@success_count} formulas created!", :green, :bright])
        elsif @success_count > 0
          Fontist.ui.say(Paint["  👍 Keep going! #{@success_count} formulas created.", :yellow, :bright])
        end

        # Show failures if any
        if @failures.any?
          Fontist.ui.say("")
          Fontist.ui.say(Paint["═" * 80, :red])
          Fontist.ui.say(Paint["  Failure Report", :red, :bright])
          Fontist.ui.say(Paint["═" * 80, :red])
          Fontist.ui.say("")

          @failures.each_with_index do |failure, index|
            Fontist.ui.say("  #{index + 1}) #{Paint[failure[:name], :yellow, :bright]}")
            Fontist.ui.say("     #{Paint['FontNotFoundError:', :red]} #{failure[:error]}")
            Fontist.ui.say("")

            # Show source information for debugging
            if failure[:url]
              Fontist.ui.say("       #{Paint['Source URL:', :cyan]}")
              Fontist.ui.say("         #{Paint[failure[:url], :white]}")
            end

            if failure[:cache_path]
              Fontist.ui.say("       #{Paint['Cached file:', :cyan]}")
              Fontist.ui.say("         #{Paint[failure[:cache_path], :white]}")
            end

            # Show parsing errors if available
            if failure[:parsing_errors].any?
              Fontist.ui.say("")
              Fontist.ui.say("       #{Paint['Font parsing errors:', :cyan]}")

              # Group errors by filename for cleaner display
              grouped = failure[:parsing_errors].group_by { |e| File.basename(e[:path]) }

              grouped.each do |filename, errors|
                Fontist.ui.say("       #{Paint['•', :red]} #{Paint[filename, :white]}")
                errors.each do |error|
                  # Show error message
                  message_lines = error[:message].scan(/.{1,70}(?:\s+|$)/)
                  message_lines.each_with_index do |line, i|
                    prefix = i == 0 ? "         " : "           "
                    Fontist.ui.say("#{prefix}#{Paint[line.strip, :red]}")
                  end

                  # Show first few lines of backtrace if available
                  if error[:backtrace] && error[:backtrace].any?
                    Fontist.ui.say("")
                    error[:backtrace].first(4).each do |trace_line|
                      # Clean up the trace line - show only relevant parts
                      clean_line = trace_line.sub(/^#{Regexp.escape(Dir.pwd)}\//, '')
                      Fontist.ui.say("           #{Paint['#', :black, :bright]} #{Paint[clean_line, :black, :bright]}")
                    end
                  end
                end
                Fontist.ui.say("") unless grouped.keys.last == filename
              end
            else
              # No parsing errors collected - provide helpful context
              Fontist.ui.say("")
              Fontist.ui.say("       #{Paint['Note:', :yellow]} No font files could be extracted or parsed from this archive.")
              Fontist.ui.say("       This may indicate:")
              Fontist.ui.say("         • Archive is empty or corrupted")
              Fontist.ui.say("         • Fonts are in an unsupported format")
              Fontist.ui.say("         • Download incomplete or failed")
              Fontist.ui.say("         • Extraction process encountered an error")
            end

            Fontist.ui.say("") unless @failures.last == failure
          end
        end

        Fontist.ui.say("")
      end

      def platforms(framework_version)
        case framework_version
        when 3
          ["macos-font3"]
        when 4
          ["macos-font4"]
        when 5
          ["macos-font5"]
        when 6
          ["macos-font6"]
        when 7
          ["macos-font7"]
        when 8
          ["macos-font8"]
        else
          ["macos"]
        end
      end

      def homepage
        HOMEPAGE
      end

      def license
        @license ||= File.read(File.expand_path("macos/macos_license.txt",
                                                __dir__))
      end

      def formula_dir(framework_version)
        @formula_dirs ||= {}
        @formula_dirs[framework_version] ||= if @custom_formulas_dir
                          Pathname.new(@custom_formulas_dir).tap do |path|
                            FileUtils.mkdir_p(path)
                          end
                        else
                          # Use versioned directory based on framework version
                          version_dir = case framework_version
                                      when 3
                                        "font3"
                                      when 4
                                        "font4"
                                      when 5
                                        "font5"
                                      when 6
                                        "font6"
                                      when 7
                                        "font7"
                                      when 8
                                        "font8"
                                      else
                                        ""
                                      end

                          base_dir = Fontist.formulas_path.join("macos")
                          base_dir = base_dir.join(version_dir) unless version_dir.empty?

                          base_dir.tap do |path|
                            FileUtils.mkdir_p(path)
                          end
                        end
      end

      def find_cached_file(url)
        cache_path = @import_cache || Fontist.import_cache_path
        cache_path = Pathname.new(cache_path) if cache_path.is_a?(String)

        # Try to find the cached file using the same naming logic as Downloader
        filename = File.basename(URI.parse(url).path)
        cached_file = cache_path.join(filename)

        cached_file.exist? ? cached_file.to_s : nil
      rescue StandardError
        nil
      end
    end
  end
end