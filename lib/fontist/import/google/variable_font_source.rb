# frozen_string_literal: true

module Fontist
  module Import
    module Google
      # The real variable font files of a family as published in the
      # google/fonts repository (METADATA.pb `fonts` entries whose filename
      # carries an axis list, e.g. "Roboto[wdth,wght].ttf").
      #
      # The Google Fonts API only serves static per-weight instances, so these
      # files are the only genuine variable sources. Google publishes them as
      # TTF only.
      class VariableFontSource
        RAW_BASE = "https://raw.githubusercontent.com/google/fonts"
        AXIS_LIST = /\[([^\]]+)\]/

        attr_reader :directory, :commit, :files, :axes

        # @param directory [String] repo-relative family dir, e.g. "ofl/roboto"
        # @param commit [String] google/fonts commit SHA the URLs are pinned to
        # @param files [Array<Models::FontFileMetadata>] METADATA.pb fonts
        # @param axes [Array<Models::AxisMetadata>] METADATA.pb axes
        def self.from_metadata(metadata, directory:, commit:)
          files = Array(metadata.fonts).select do |font|
            font.filename.to_s.match?(AXIS_LIST)
          end
          return nil if files.empty? || commit.to_s.empty?

          new(directory: directory, commit: commit, files: files,
              axes: Array(metadata.axes))
        end

        def initialize(directory:, commit:, files:, axes:)
          @directory = directory
          @commit = commit
          @files = files
          @axes = axes
        end

        def urls
          files.map { |file| url_for(file.filename) }
        end

        # Axis tags in METADATA.pb order, limited to those the files carry.
        def axis_tags
          present = files.flat_map { |file| tags_in(file.filename) }.uniq
          declared = axes.map(&:tag)
          (declared & present) + (present - declared)
        end

        # Resource entry for a v5 formula (TTF only).
        def resource(family_name)
          {
            "source" => "google",
            "family" => family_name,
            "files" => urls,
            "urls" => urls,
            "format" => "ttf",
            "variable_axes" => axis_tags,
          }
        end

        # One style per variable file, described by METADATA.pb.
        def styles
          files.map { |file| style_for(file) }
        end

        private

        def style_for(file)
          names_of(file).merge(
            "font" => file.filename,
            "formats" => ["ttf"],
            "variable_font" => true,
            "variable_axes" => tags_in(file.filename),
            "source_resource" => "ttf_variable",
          ).compact
        end

        def names_of(file)
          {
            "family_name" => file.name,
            "type" => file.style.to_s == "italic" ? "Italic" : "Regular",
            "full_name" => file.full_name,
            "post_script_name" => file.post_script_name,
            "copyright" => file.copyright,
          }
        end

        def tags_in(filename)
          filename[AXIS_LIST, 1].to_s.split(",")
        end

        def url_for(filename)
          # Brackets stay literal: the installer matches style files against
          # the URL basename, which must equal the downloaded file name.
          encoded = filename.gsub(/[^A-Za-z0-9._,\-\[\]]/) do |char|
            char.bytes.map { |b| format("%%%02X", b) }.join
          end
          "#{RAW_BASE}/#{commit}/#{directory}/#{encoded}"
        end
      end
    end
  end
end
