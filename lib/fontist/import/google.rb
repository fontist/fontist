module Fontist
  module Import
    module Google
      def self.formula_path(name)
        filename = name.downcase.gsub(" ", "_") + "_font.rb"
        Fontist.formulas_path.join("google", filename)
      end

      def self.style_version(text)
        return unless text

        text.gsub("Version ", "")
      end
    end
  end
end
