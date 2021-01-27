module Fontist
  module Indexes
    class IndexFormula
      def initialize(path)
        @path = path
      end

      def name
        normalized.sub(/\.yml$/, "")
      end

      def to_s
        normalized
      end

      def to_full
        Formula.new_from_file(full_path)
      end

      def ==(other)
        to_s == other.to_s
      end

      private

      def normalized
        escaped = Regexp.escape(Fontist.formulas_path.to_s + "/")
        @path.sub(Regexp.new("^" + escaped), "")
      end

      def full_path
        Fontist.formulas_path.join(normalized).to_s
      end
    end
  end
end
