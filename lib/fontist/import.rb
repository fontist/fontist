module Fontist
  module Import
    class << self
      def name_to_filename(name)
        "#{name.downcase.gsub(' ', '_')}.yml"
      end

      # Normalize a font name to a consistent base filename (without extension)
      # This MUST match the normalization in FormulaBuilder#generate_filename
      #
      # @param name [String] Font family name
      # @return [String] Normalized base filename (no extension)
      def normalize_filename(name)
        name.downcase.gsub(" ", "_")
      end
    end
  end
end
