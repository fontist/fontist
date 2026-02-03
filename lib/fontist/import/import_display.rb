require "paint"

module Fontist
  module Import
    # Unified progress display for all import commands
    #
    # Provides consistent, professional Paint-colored output with emojis
    # across Google, SIL, and macOS importers.
    module ImportDisplay
      # Display import header with Paint styling
      #
      # @param source [String] Import source name (e.g., "Google Fonts", "SIL International")
      # @param details [Hash] Details to display (e.g., {output_path: "...", font_filter: "..."})
      # @param import_cache [String, Pathname] Import cache location (optional)
      def self.header(source, details = {}, import_cache: nil)
        Fontist.ui.say("")
        Fontist.ui.say(Paint["═" * 80, :cyan])
        Fontist.ui.say(Paint["  📦 #{source} Import", :cyan, :bright])
        Fontist.ui.say(Paint["═" * 80, :cyan])
        Fontist.ui.say("")

        # Show import cache if provided
        if import_cache
          cache_path = import_cache.is_a?(Pathname) ? import_cache.to_s : import_cache.to_s
          Fontist.ui.say("📦 Import cache: #{Paint[cache_path, :white]}")
        end

        # Show other details
        details.each do |key, value|
          next unless value

          label = key.to_s.split("_").map(&:capitalize).join(" ")
          Fontist.ui.say("📁 #{label}: #{Paint[value.to_s, :white]}")
        end

        Fontist.ui.say("")
      end

      # Display progress update with Paint styling
      #
      # @param current [Integer] Current count
      # @param total [Integer] Total count
      # @param item [String] Item being processed
      # @param details [String] Optional details (e.g., "(3 fonts)")
      def self.progress(current, total, item, details: nil)
        progress_text = "(#{current}/#{total})"
        percentage = ((current.to_f / total) * 100).round(1)

        line = "#{Paint[progress_text, :white]} " \
               "#{Paint["#{percentage}%", :yellow]} | " \
               "#{Paint[item, :cyan, :bright]}"

        line += " #{Paint[details, :black, :bright]}" if details

        Fontist.ui.say(line)
      end

      # Display success status
      #
      # @param message [String] Success message
      # @param details [String] Optional details (e.g., formula name, timing)
      def self.status_success(message, details = "")
        detail_text = if details.empty?
                        ""
                      else
                        " #{Paint[details, :black,
                                  :bright]}"
                      end
        Fontist.ui.say("  #{Paint['✓',
                                  :green]} #{Paint[message,
                                                   :white]}#{detail_text}")
      end

      # Display skip status
      #
      # @param message [String] Skip message
      # @param tip [String] Optional tip for user
      def self.status_skipped(message, tip: nil)
        Fontist.ui.say("  #{Paint['⊝', :yellow]} #{message}")
        Fontist.ui.say("    #{Paint['ℹ', :blue]} #{tip}") if tip
      end

      # Display failure status
      #
      # @param message [String] Error message
      def self.status_failed(message)
        error_display = message.length > 60 ? "#{message[0..60]}..." : message
        Fontist.ui.say("  #{Paint['✗',
                                  :red]} Failed: #{Paint[error_display, :red]}")
      end

      # Display overwrite warning
      #
      # @param message [String] Warning message
      def self.status_overwrite(message)
        Fontist.ui.say("  #{Paint['⚠', :yellow]} #{message}")
      end

      # Display summary with Paint styling
      #
      # @param results [Hash] Results hash with :successful, :failed, :duration keys
      # @param options [Hash] Display options (:force, :show_tips, etc.)
      def self.summary(results, options = {})
        print_summary_header
        print_summary_stats(results)
        print_summary_errors(results) if results[:errors]&.any?
        print_summary_tips(results, options)
        print_summary_footer(results)
      end

      # Display section header
      #
      # @param title [String] Section title (deprecated - use header instead)
      def self.section(title)
        Fontist.ui.say("")
        Fontist.ui.say("── #{title} " + "─" * (76 - title.length))
        Fontist.ui.say("")
      end

      # Display info message
      #
      # @param message [String] Info message
      def self.info(message)
        Fontist.ui.say("  ℹ️  #{message}")
      end

      # Display error message
      #
      # @param message [String] Error message
      def self.error(message)
        Fontist.ui.error("❌ #{message}")
      end

      # Display warning message
      #
      # @param message [String] Warning message
      def self.warn(message)
        Fontist.ui.say("  ⚠️  #{message}")
      end

      # Display debug/info message in gray bold (like macOS import)
      #
      # @param message [String] Debug message
      def self.debug_info(message)
        Fontist.ui.say("    #{Paint[message, :black, :bright]}")
      end

      # Display page URL being visited
      #
      # @param url [String] Page URL
      def self.page_url(url)
        Fontist.ui.say("  #{Paint['🔗', :blue]} Page URL: #{Paint[url, :white]}")
      end

      # Display download URL
      #
      # @param url [String] Download URL
      def self.download_url(url)
        Fontist.ui.say("  #{Paint['📥',
                                  :green]} Download URL: #{Paint[url, :white]}")
      end

      # Display "Following link..." message
      #
      # @param text [String] Link description
      def self.following_link(text)
        debug_info("Following #{text}...")
      end

      # Display "Found N elements" message
      #
      # @param count [Integer] Number of elements
      # @param selector [String] CSS selector name
      def self.found_elements(count, selector)
        debug_info("Found #{count} '#{selector}' elements") if count.positive?
      end

      # Format duration in human-readable format
      #
      # @param seconds [Float] Duration in seconds
      # @return [String] Formatted duration
      def self.format_duration(seconds)
        return "#{seconds.round(2)}s" if seconds < 60

        minutes = (seconds / 60).floor
        remaining = (seconds % 60).round(2)

        if minutes < 60
          "#{minutes}m #{remaining}s"
        else
          hours = (minutes / 60).floor
          remaining_minutes = minutes % 60
          "#{hours}h #{remaining_minutes}m #{remaining.round}s"
        end
      end

      class << self
        private

        def print_summary_header
          Fontist.ui.say("")
          Fontist.ui.say(Paint["═" * 80, :cyan])
          Fontist.ui.say(Paint["  📊 Import Summary", :cyan, :bright])
          Fontist.ui.say(Paint["═" * 80, :cyan])
          Fontist.ui.say("")
        end

        def print_summary_stats(results)
          total = calculate_total(results)
          return if total.zero?

          success_rate = (results[:successful].to_f / total * 100).round(1)

          Fontist.ui.say("  Total packages:     #{Paint[total.to_s, :white]}")
          Fontist.ui.say("  #{Paint['✓',
                                    :green]} Successful:     #{Paint[results[:successful].to_s, :green,
                                                                     :bright]} #{Paint["(#{success_rate}%)",
                                                                                       :green]}")

          if results[:skipped]&.positive?
            skip_rate = (results[:skipped].to_f / total * 100).round(1)
            Fontist.ui.say("  #{Paint['⊝',
                                      :yellow]} Skipped:        #{Paint[results[:skipped].to_s,
                                                                        :yellow]} #{Paint["(#{skip_rate}%)",
                                                                                          :yellow]} #{Paint['(already exists)',
                                                                                                            :black, :bright]}")
          end

          if results[:overwritten]&.positive?
            Fontist.ui.say("  #{Paint['⚠',
                                      :yellow]} Overwritten:    #{Paint[results[:overwritten].to_s,
                                                                        :yellow]}")
          end

          if results[:failed]&.positive?
            fail_rate = (results[:failed].to_f / total * 100).round(1)
            Fontist.ui.say("  #{Paint['✗',
                                      :red]} Failed:         #{Paint[results[:failed].to_s,
                                                                     :red]} #{Paint["(#{fail_rate}%)",
                                                                                    :red]}")
          end

          Fontist.ui.say("")
        end

        def print_summary_errors(results)
          return unless results[:errors]&.any?

          Fontist.ui.say("  #{Paint['⚠',
                                    :yellow]} Note: #{results[:failed]} font#{results[:failed] > 1 ? 's' : ''} failed during import.")
          Fontist.ui.say("")
        end

        def print_summary_tips(results, options)
          # Show force tip if there were skipped formulas
          if results[:skipped]&.positive? && !options[:force]
            Fontist.ui.say("  #{Paint['💡 Tip:',
                                      :cyan]} Use #{Paint['--force', :cyan,
                                                          :bright]} to overwrite existing formulas")
            Fontist.ui.say("")
          end
        end

        def print_summary_footer(results)
          total = calculate_total(results)
          return if total.zero?

          if results[:successful] > (total * 0.5)
            Fontist.ui.say(Paint["  🎉 Great success! #{results[:successful]} formula#{results[:successful] > 1 ? 's' : ''} created!",
                                 :green, :bright])
          elsif results[:successful].positive?
            Fontist.ui.say(Paint["  👍 Keep going! #{results[:successful]} formula#{results[:successful] > 1 ? 's' : ''} created.",
                                 :yellow, :bright])
          end

          Fontist.ui.say("")
        end

        def calculate_total(results)
          results[:total] || (results[:successful] || 0) + (results[:failed] || 0) + (results[:skipped] || 0)
        end
      end
    end
  end
end
