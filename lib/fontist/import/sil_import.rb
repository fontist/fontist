require "nokogiri"
require "fontist/import/create_formula"
require_relative "../sil_import_source"
require_relative "import_display"
require "paint"

module Fontist
  module Import
    class SilImport
      ROOT = "https://software.sil.org/fonts/".freeze

      def initialize(options = {})
        @output_path = options[:output_path]
        @font_name = options[:font_name]
        @verbose = options[:verbose]
        @import_cache = options[:import_cache]
        @force = options[:force]
        @success_count = 0
        @failure_count = 0
        @skipped_count = 0
        @overwritten_count = 0
        @failures = [] # Track {name, reason} for each failure
      end

      def call
        start_time = Time.now

        # Display header with import cache
        display_header

        # Fetch links
        links = fetch_and_filter_fonts

        return empty_result if links.empty?

        # Process fonts
        process_fonts(links)

        # Display summary
        display_summary(links.size, Time.now - start_time)

        # Display failures if any
        display_failures if @failures.any?

        build_results(Time.now - start_time)
      end

      private

      def display_header
        cache_path = @import_cache || Fontist.import_cache_path
        details = { output_path: formula_dir.to_s }
        details[:font_filter] = @font_name if @font_name

        if @verbose
          ImportDisplay.header("SIL International Fonts", details,
                               import_cache: cache_path)
        end
      end

      def fetch_and_filter_fonts
        if @verbose
          Fontist.ui.say("🔍 Fetching font list from SIL website...")
          Fontist.ui.say("")
        end

        links = font_links

        if @verbose
          Fontist.ui.say("📦 Found #{Paint[links.size, :yellow,
                                           :bright]} fonts on SIL website")
        end

        # Filter by font_name if specified
        if @font_name
          links.size
          links = filter_by_name(links)
          if @verbose
            Fontist.ui.say("🔍 Filter: #{Paint[@font_name, :cyan, :bright]}")
            Fontist.ui.say("📦 Filtered to #{Paint[links.size, :yellow,
                                                   :bright]} fonts matching filter")
          end

          if links.empty?
            Fontist.ui.error("No fonts matching '#{@font_name}' found")
          end
        end

        if @verbose
          Fontist.ui.say("📁 Saving formulas to: #{Paint[formula_dir, :cyan]}")
          Fontist.ui.say("")
        end

        links
      end

      def process_fonts(links)
        links.each_with_index do |link, index|
          process_single_font(link, index + 1, links.size)
        end
      end

      def process_single_font(link, current, total)
        family_name = link.content

        # Display progress
        ImportDisplay.progress(current, total, family_name) if @verbose

        # Get archive URL
        url = find_archive_url_by_page_link(link)
        return unless url

        start_time = Time.now
        version = extract_version_from_url(url)
        import_source = create_import_source(version)

        path = create_formula_by_archive_url(url, import_source)

        if path
          elapsed = Time.now - start_time

          # Check if the file was just created (modified within last 2 seconds) or already existed
          file_modified_time = File.mtime(path)
          was_just_created = (Time.now - file_modified_time) < 2

          if was_just_created
            @success_count += 1
            formula_name = File.basename(path)
            if @verbose
              Fontist.ui.say("  #{Paint['✓',
                                        :green]} Formula created: #{Paint[formula_name,
                                                                          :white]} #{Paint["(#{elapsed.round(2)}s)",
                                                                                           :black, :bright]}")
            end
          else
            # File already existed and was skipped by keep_existing check
            @skipped_count += 1
            formula_name = File.basename(path)
            if @verbose
              Fontist.ui.say("  #{Paint['⊝',
                                        :yellow]} Skipped (already exists): #{Paint[formula_name,
                                                                                    :black, :bright]}")
              Fontist.ui.say("    #{Paint['ℹ',
                                          :blue]} Use #{Paint['--force',
                                                              :cyan]} to overwrite existing formulas")
            end
          end
        else
          @failure_count += 1
          @failures << { name: family_name, reason: "Formula creation failed" }
          if @verbose
            Fontist.ui.say("  #{Paint['✗', :red]} Failed")
          end
        end
      rescue StandardError => e
        @failure_count += 1
        error_msg = e.message.length > 60 ? "#{e.message[0..60]}..." : e.message
        @failures << { name: family_name, reason: error_msg }
        if @verbose
          Fontist.ui.say("  #{Paint['✗',
                                    :red]} Failed: #{Paint[error_msg,
                                                           :red]}")
        end
      end

      def display_summary(total, _duration)
        return unless @verbose

        Fontist.ui.say("")
        Fontist.ui.say(Paint["═" * 80, :cyan])
        Fontist.ui.say(Paint["  📊 Import Summary", :cyan, :bright])
        Fontist.ui.say(Paint["═" * 80, :cyan])
        Fontist.ui.say("")

        success_rate = (@success_count.to_f / total * 100).round(1)

        Fontist.ui.say("  Total fonts:        #{Paint[total.to_s, :white]}")
        Fontist.ui.say("  #{Paint['✓',
                                  :green]} Successful:     #{Paint[@success_count.to_s, :green,
                                                                   :bright]} #{Paint["(#{success_rate}%)",
                                                                                     :green]}")

        if @skipped_count.positive?
          skip_rate = (@skipped_count.to_f / total * 100).round(1)
          Fontist.ui.say("  #{Paint['⊝',
                                    :yellow]} Skipped:        #{Paint[@skipped_count.to_s,
                                                                      :yellow]} #{Paint["(#{skip_rate}%)",
                                                                                        :yellow]} #{Paint['(already exists)',
                                                                                                          :black, :bright]}")
        end

        if @overwritten_count.positive?
          Fontist.ui.say("  #{Paint['⚠',
                                    :yellow]} Overwritten:    #{Paint[@overwritten_count.to_s,
                                                                      :yellow]}")
        end

        if @failure_count.positive?
          fail_rate = (@failure_count.to_f / total * 100).round(1)
          Fontist.ui.say("  #{Paint['✗',
                                    :red]} Failed:         #{Paint[@failure_count.to_s,
                                                                   :red]} #{Paint["(#{fail_rate}%)",
                                                                                  :red]}")
        end

        if @skipped_count.positive? && !@force
          Fontist.ui.say("")
          Fontist.ui.say("  #{Paint['💡 Tip:',
                                    :cyan]} Use #{Paint['--force', :cyan,
                                                        :bright]} to overwrite existing formulas:")
          Fontist.ui.say("    fontist import sil --output-path=<path> --force")
        end

        Fontist.ui.say("")

        if @success_count > (total * 0.5)
          Fontist.ui.say(Paint["  🎉 Great success! #{@success_count} formulas created!",
                               :green, :bright])
        elsif @success_count.positive?
          Fontist.ui.say(Paint["  👍 Keep going! #{@success_count} formulas created.",
                               :yellow, :bright])
        end

        # Show failures if any
        if @failures.any?
          Fontist.ui.say("")
          Fontist.ui.say(Paint["═" * 80, :cyan])
          Fontist.ui.say(Paint["  ❌ Failed Imports", :red, :bright])
          Fontist.ui.say(Paint["═" * 80, :cyan])
          Fontist.ui.say("")

          @failures.each_with_index do |failure, index|
            Fontist.ui.say("  #{index + 1}. #{Paint[failure[:name],
                                                    :yellow]} - #{Paint[failure[:reason],
                                                                        :red]}")
          end
        end

        Fontist.ui.say("")
      end

      def display_failures
        return unless @verbose

        Fontist.ui.say("")
        Fontist.ui.say(Paint["═" * 80, :red])
        Fontist.ui.say(Paint["  🚫 Failed Fonts", :red, :bright])
        Fontist.ui.say(Paint["═" * 80, :red])
        Fontist.ui.say("")

        @failures.each do |failure|
          Fontist.ui.say("  #{Paint['✗',
                                    :red]} #{Paint[failure[:name],
                                                   :white]}: #{Paint[failure[:reason],
                                                                     :red]}")
        end

        Fontist.ui.say("")
      end

      def empty_result
        { successful: 0, failed: 0, errors: [], duration: 0 }
      end

      def build_results(duration)
        {
          successful: @success_count,
          failed: @failure_count,
          skipped: @skipped_count,
          overwritten: @overwritten_count,
          errors: [],
          duration: duration,
        }
      end

      def font_links
        html = URI.parse(ROOT).open.read
        document = Nokogiri::HTML.parse(html)
        document.css("table.products div.title > a")
      end

      def filter_by_name(links)
        links.select do |link|
          link.content.downcase.include?(@font_name.downcase)
        end
      end

      def create_formula_by_page_link(link)
        url = find_archive_url_by_page_link(link)
        return unless url

        # Extract version and create import_source
        version = extract_version_from_url(url)
        import_source = create_import_source(version)

        create_formula_by_archive_url(url, import_source)
      rescue StandardError => e
        ImportDisplay.error("Error creating formula: #{e.message}") if @verbose
        nil
      end

      def create_formula_by_archive_url(url, import_source = nil)
        options = { formula_dir: formula_dir.to_s }
        options[:import_source] = import_source if import_source
        options[:import_cache] = @import_cache if @import_cache
        options[:keep_existing] = !@force
        # All SIL fonts use the SIL Open Font License
        options[:open_license] = "OFL-1.1"

        Fontist::Import::CreateFormula.new(url, options).call
      end

      # Extract version from URL
      #
      # SIL fonts typically include version in the filename or URL
      # Examples:
      #   - CharisSIL-6.200.zip
      #   - Andika-6.101.zip
      #
      # @param url [String] Archive URL
      # @return [String, nil] Extracted version or nil
      def extract_version_from_url(url)
        # Match version patterns like 6.200, 1.0.0, 2.1, etc.
        match = url.match(/[-_]v?(\d+\.\d+(?:\.\d+)?)(?:[-_.]|\.zip|\.tar)/i)
        return match[1] if match

        # Fallback: try to extract any version-like string
        match = url.match(/(\d+\.\d+\.\d+|\d+\.\d+)/)
        match ? match[1] : nil
      end

      # Create SilImportSource with version and release date
      #
      # @param version [String, nil] Font version
      # @return [SilImportSource, nil] Import source or nil if no version
      def create_import_source(version)
        return nil unless version

        Fontist::SilImportSource.new(
          version: version,
          release_date: Time.now.utc.iso8601,
        )
      end

      def find_archive_url_by_page_link(link)
        family_name = link.content

        # Skip known index pages that just link to other fonts
        if index_page?(family_name)
          if @verbose
            Fontist.ui.say("  #{Paint['⊝',
                                      :yellow]} Skipped (index page): #{Paint[family_name,
                                                                              :black, :bright]}")
          end
          return nil
        end

        # Search quietly in verbose mode, show progress in non-verbose
        unless @verbose
          Fontist.ui.print("Searching for an archive of #{family_name}... ")
        end

        page_uri = URI.join(ROOT, link[:href])

        ImportDisplay.page_url(page_uri.to_s) if @verbose

        archive_uri = find_archive_url_by_page_uri(page_uri)

        unless archive_uri
          if @verbose
            Fontist.ui.say("  #{Paint['✗', :red]} No archive found")
          else
            Fontist.ui.error("NOT FOUND")
          end
          return
        end

        ImportDisplay.download_url(archive_uri.to_s) if @verbose
        Fontist.ui.success("DONE") unless @verbose

        archive_uri.to_s
      end

      # Check if this is an index page that just links to other fonts
      def index_page?(name)
        index_pages = [
          "Arabic Fonts",
          "Latin, Greek, and Cyrillic Fonts",
          "African Latin Fonts",
          "Asian Latin Fonts",
        ]
        index_pages.any? { |page| name.strip.casecmp?(page) }
      end

      def find_archive_url_by_page_uri(uri)
        response = uri.open
        current_url = response.base_uri
        html = response.read
        document = Nokogiri::HTML.parse(html)

        if @verbose
          # Debug: Show what selectors find using standardized method
          btn_downloads = document.css("a.btn-download")
          ImportDisplay.found_elements(btn_downloads.size, "a.btn-download")
        end

        link = find_archive_link(document)
        return URI.join(current_url, link[:href]) if link

        page_link = find_download_page(document)

        if @verbose && page_link
          ImportDisplay.following_link("'DOWNLOADS' page link")
        end

        return unless page_link

        page_uri = URI.join(current_url, page_link[:href])
        find_archive_url_by_page_uri(page_uri)
      end

      def find_archive_link(document)
        # Try 1: Look for direct download link with btn-download class pointing to .zip
        links = document.css("a.btn-download")
        download_links = links.select do |tag|
          tag[:href]&.end_with?(".zip")
        end
        return download_links.first if download_links.any?

        # Try 2: Look for old-style "DOWNLOAD CURRENT VERSION" text
        download_links = links.select do |tag|
          tag.content.include?("DOWNLOAD CURRENT VERSION")
        end
        return download_links.first unless download_links.empty?

        # Try 3: Look for links with class "getfile" that point to .zip files
        links = document.css("a.getfile")
        download_links = links.select do |tag|
          tag[:href]&.end_with?(".zip")
        end
        return download_links.first if download_links.any?

        # Try 4: Look for any link text matching "Download.*\.zip"
        links = document.css("a")
        download_links = links.select do |tag|
          tag.content.match?(/Download.*\.zip/)
        end
        download_links.first
      end

      def find_download_page(document)
        links = document.css("a.btn-download")
        # Try both old "DOWNLOADS" and new "Downloads" text
        page_links = links.select do |tag|
          tag.content.strip.match?(/^DOWNLOADS?$/i)
        end
        page_links.first
      end

      # Predict formula path based on family name and version
      def predicted_formula_path(family_name, version)
        return nil unless version
        return nil unless family_name

        normalized_name = Fontist::Import.normalize_filename(family_name)
        predicted_path = formula_dir.join("#{normalized_name}_#{version}.yml")

        # Debug logging if verbose
        if @verbose
          Fontist.ui.debug("  Predicted path: #{predicted_path}")
          Fontist.ui.debug("  File exists?: #{File.exist?(predicted_path)}")
        end

        predicted_path
      rescue StandardError => e
        Fontist.ui.error("WARN: Error predicting formula path: #{e.message}") if @verbose
        nil
      end

      def formula_dir
        @formula_dir ||= if @output_path
                           Pathname.new(@output_path).tap do |path|
                             FileUtils.mkdir_p(path)
                           end
                         else
                           Fontist.formulas_path.join("sil").tap do |path|
                             FileUtils.mkdir_p(path)
                           end
                         end
      end
    end
  end
end
