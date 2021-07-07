module Fontist
  module Import
    class OtfStyle
      def initialize(info, path)
        @info = info
        @path = path
      end

      def call
        style = { family_name: @info["Preferred family"] || @info["Family"],
                  style: @info["Preferred subfamily"] || @info["Subfamily"],
                  full_name: @info["Full name"],
                  post_script_name: @info["PostScript name"],
                  version: version(@info["Version"]),
                  description: @info["Description"],
                  filename: File.basename(@path),
                  copyright: @info["Copyright"] }

        style[:default_family_name] = @info["Family"] if @info["Family"] != style[:family_name]
        style[:default_style] = @info["Subfamily"] if @info["Subfamily"] != style[:style]

        OpenStruct.new(style)
      end

      private

      def version(text)
        Fontist::Import::Google.style_version(text)
      end
    end
  end
end
