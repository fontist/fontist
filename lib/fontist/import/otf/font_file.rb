require_relative "../otfinfo/otfinfo_requirement"
require_relative "../text_helper"

module Fontist
  module Import
    module Otf
      class FontFile
        REQUIREMENTS = {
          otfinfo: Otfinfo::OtfinfoRequirement.new,
        }.freeze

        STYLE_ATTRIBUTES = %i[family_name type full_name post_script_name
                              version description copyright font].freeze
        COLLECTION_ATTRIBUTES = STYLE_ATTRIBUTES.reject { |a| a == :font }

        attr_reader :path

        def initialize(path)
          @path = path
          @info = read
        end

        def to_style
          STYLE_ATTRIBUTES.map { |name| [name, send(name)] }.to_h.compact
        end

        def to_collection_style
          COLLECTION_ATTRIBUTES.map { |name| [name, send(name)] }.to_h.compact
        end

        def family_name
          info["Preferred family"] || info["Family"]
        end

        def type
          info["Preferred subfamily"] || info["Subfamily"]
        end

        def full_name
          info["Full name"]
        end

        def post_script_name
          info["PostScript name"]
        end

        def version
          return unless info["Version"]

          info["Version"].gsub("Version ", "")
        end

        def description
          info["Description"]
        end

        def font
          File.basename(@path)
        end

        def copyright
          info["Copyright"]
        end

        def homepage
          info["Vendor URL"]
        end

        def license_url
          info["License URL"]
        end

        private

        attr_reader :info

        def read
          text = REQUIREMENTS[:otfinfo].call(@path)

          text
            .encode("UTF-8", invalid: :replace, replace: "")
            .split("\n")
            .select { |x| x.include?(":") }
            .map { |x| x.split(":", 2) }
            .map { |x| x.map { |y| Fontist::Import::TextHelper.cleanup(y) } }
            .to_h
        end
      end
    end
  end
end
