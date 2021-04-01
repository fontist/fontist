require_relative "index_formula"

module Fontist
  module Indexes
    class BaseIndex
      def self.from_yaml
        @from_yaml ||= begin
          unless File.exist?(path)
            raise Errors::FormulaIndexNotFoundError.new("Please fetch `#{path}` index with `fontist update`.")
          end

          data = YAML.load_file(path)
          new(data)
        end
      end

      def self.path
        raise NotImplementedError, "Please define path of an index"
      end

      def self.reset_cache
        @from_yaml = nil
      end

      def self.rebuild
        index = new
        index.build
        index.to_yaml
      end

      def initialize(data = {})
        @index = {}

        data.each_pair do |key, paths|
          paths.each do |path|
            add_index_formula(key, IndexFormula.new(path))
          end
        end
      end

      def build
        Formula.all.each do |formula|
          add_formula(formula)
        end
      end

      def add_formula(_formula)
        raise NotImplementedError, "Please define how to add formula to an index, use #add_index_formula"
      end

      def add_index_formula(key_raw, index_formula)
        key = normalize_key(key_raw)
        @index[key] ||= []
        @index[key] << index_formula unless @index[key].include?(index_formula)
      end

      def load_formulas(key)
        index_formulas(key).map(&:to_full)
      end

      def load_index_formulas(key)
        index_formulas(key)
      end

      def to_yaml
        File.write(self.class.path, YAML.dump(to_h))
      end

      def to_h
        @index.map do |key, index_formulas|
          [key, index_formulas.map(&:to_s)]
        end.to_h
      end

      private

      def index_formulas(key)
        @index[normalize_key(key)] || []
      end

      def normalize_key(key)
        key
      end
    end
  end
end
