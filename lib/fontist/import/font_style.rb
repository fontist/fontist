module Fontist
  module Import
    class FontStyle
      attr_reader :family_name, :style, :full_name, :post_script_name,
                  :version, :description, :filename, :copyright,
                  :preferred_family_name, :preferred_style

      def initialize(attributes = {})
        @family_name = attributes[:family_name]
        @style = attributes[:style]
        @full_name = attributes[:full_name]
        @post_script_name = attributes[:post_script_name]
        @version = attributes[:version]
        @description = attributes[:description]
        @filename = attributes[:filename]
        @copyright = attributes[:copyright]
        @preferred_family_name = attributes[:preferred_family_name]
        @preferred_style = attributes[:preferred_style]
      end
    end
  end
end
