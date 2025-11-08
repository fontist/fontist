require_relative "font_style"

module Fontist
  module Import
    class OtfStyle
      def initialize(info, path)
        @info = info
        @path = path
      end

      def call
        style = { family_name: @info["Family"],
                  style: @info["Subfamily"],
                  full_name: @info["Full name"],
                  post_script_name: @info["PostScript name"],
                  version: version(@info["Version"]),
                  description: @info["Description"],
                  filename: File.basename(@path),
                  copyright: @info["Copyright"] }

        if @info["Preferred family"]
          style[:preferred_family_name] = @info["Preferred family"]
        end

        if @info["Preferred subfamily"]
          style[:preferred_style] = @info["Preferred subfamily"]
        end

        FontStyle.new(style)
      end

      private

      def version(text)
        Fontist::Import::Google.style_version(text)
      end
    end
  end
end
