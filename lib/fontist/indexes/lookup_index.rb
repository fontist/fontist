module Fontist
  module Indexes
    # Read-only lookups over the JSON sidecar written beside an index
    # file. Binding every index entry into model objects dominates the
    # cost of loading an index; the sidecar holds the key-to-path map
    # as plain data, and FormulaKeyToPath entries are materialized only
    # for the requested key.
    class LookupIndex
      def initialize(entries_hash, normalizer:)
        @entries_hash = entries_hash
        @normalizer = normalizer
      end

      def load_index_formulas(key)
        [
          FormulaKeyToPath.new(
            key: key,
            formula_path: paths_for(@normalizer.call(key)),
          ),
        ]
      end

      def load_formulas(key)
        load_index_formulas(key).flat_map(&:to_full)
      end

      private

      def paths_for(normalized_key)
        @entries_hash[normalized_key] || []
      end
    end
  end
end
