module Fontist
  module Indexes
    module IndexMixin
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def from_file(file_path = self.path)
          Fontist.ui.debug("Index: #{file_path}")

          unless Dir.exist?(Fontist.formulas_repo_path)
            raise Errors::MainRepoNotFoundError.new(
              "Please fetch formulas with `fontist update`.",
            )
          end

          rebuild unless File.exist?(file_path)

          file_content = File.read(file_path).strip

          if file_content.empty?
            raise Fontist::Errors::FontIndexCorrupted, "Index file is empty: #{file_path}"
          end

          from_yaml(file_content)
        end

        def rebuild
          # puts "Rebuilding index..."
          new.build
        end
      end

      def build
        Formula.all.each do |formula|
          add_formula(formula)
        end

        to_file

        self
      end

      def add_formula(formula)
        raise unless formula.is_a?(Formula)

        fonts = formula.fonts
        fonts = fonts + collection_fonts(formula.font_collections) if formula.font_collections

        fonts.each do |font|
          font.styles.each do |style|
            add_index_formula(style, formula.path)
          end
        end

        entries
      end

      def collection_fonts(collection)
        collection.flat_map do |c|
          c.fonts.flat_map do |f|
            f.styles.each do |s|
              s.font = c.filename
              s.source_font = c.source_filename
            end
            f
          end
        end
      end

      def load_formulas(key)
        index_formulas(key).flat_map(&:to_full)
      end

      def load_index_formulas(key)
        index_formulas(key)
      end

      def to_file(file_path = self.class.path)
        # Use default path if file_path is nil
        file_path = self.class.path if file_path.nil?
        # puts "Writing index to #{file_path}"

        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, to_yaml)
      end

      private

      def index_formula(key)
        Array(entries).detect { |f| f.key.casecmp(key).zero? }
      end

      def index_formulas(key)
        Array(entries).select { |f| f.key.casecmp(key).zero? }
      end

      def relative_formula_path(path)
        escaped = Regexp.escape("#{Fontist.formulas_path}/")
        path.sub(Regexp.new("^#{escaped}"), "")
      end
    end
  end
end
