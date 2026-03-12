module Fontist
  module Import
    autoload :ConvertFormulas, "#{__dir__}/import/convert_formulas"
    autoload :CreateFormula, "#{__dir__}/import/create_formula"
    autoload :Files, "#{__dir__}/import/files"
    autoload :FontMetadataExtractor, "#{__dir__}/import/font_metadata_extractor"
    autoload :FontParsingErrorCollector, "#{__dir__}/import/font_parsing_error_collector"
    autoload :FontStyle, "#{__dir__}/import/font_style"
    autoload :FormulaBuilder, "#{__dir__}/import/formula_builder"
    autoload :FormulaSerializer, "#{__dir__}/import/formula_serializer"
    autoload :Google, "#{__dir__}/import/google"
    autoload :GoogleFontsImporter, "#{__dir__}/import/google_fonts_importer"
    autoload :GoogleImport, "#{__dir__}/import/google_import"
    autoload :Helpers, "#{__dir__}/import/helpers"
    autoload :ImportDisplay, "#{__dir__}/import/import_display"
    autoload :Macos, "#{__dir__}/import/macos"
    autoload :ManualFormulaBuilder, "#{__dir__}/import/manual_formula_builder"
    autoload :Models, "#{__dir__}/import/models"
    autoload :Otf, "#{__dir__}/import/otf"
    autoload :RecursiveExtraction, "#{__dir__}/import/recursive_extraction"
    autoload :SilImport, "#{__dir__}/import/sil_import"
    autoload :TemplateHelper, "#{__dir__}/import/template_helper"
    autoload :TextHelper, "#{__dir__}/import/text_helper"
    autoload :UpgradeFormulas, "#{__dir__}/import/upgrade_formulas"

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
