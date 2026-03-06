module Fontist
  module Indexes
    # IndexMixin provides common functionality for font index classes.
    #
    # == Performance Optimization (Tech Debt)
    #
    # This module uses a temporary Hash-based lookup cache during index building
    # to avoid O(n²) performance when adding many entries. This is a workaround
    # for Lutaml::Model::Collection's Array-based storage.
    #
    # === The Problem
    #
    # Lutaml::Model::Collection stores entries as an Array, which provides O(n)
    # lookup when searching for existing keys. When building an index with
    # thousands of entries, this creates O(n²) behavior:
    #
    # - 8867 font styles × average 2670 comparisons = ~23.6 million comparisons
    # - Index building: ~26 seconds with Array lookup
    #
    # === The Workaround
    #
    # During `build` and `build_with_formulas`, we maintain a temporary
    # `@index_build_cache` Hash that provides O(1) lookups. After building,
    # the cache is cleared.
    #
    # - Index building with Hash lookup: ~0.08 seconds
    # - Speedup: 325× faster
    #
    # === The Proper Fix
    #
    # This tech debt should be resolved by enhancing Lutaml::Model::Collection
    # to support efficient key-based lookups. See the reproduction script at:
    # `dev/lutaml_model_collection_lookup_benchmark.rb`
    #
    # Related issue: https://github.com/lutaml/lutaml-model/issues/XXX
    #
    module IndexMixin
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def from_file(file_path = path)
          Fontist.ui.debug("Index: #{file_path}")

          Fontist.formulas_repo_path_exists!

          rebuild unless File.exist?(file_path)

          file_content = File.read(file_path).strip

          if file_content.empty?
            raise Fontist::Errors::FontIndexCorrupted,
                  "Index file is empty: #{file_path}"
          end

          from_yaml(file_content)
        end

        def rebuild
          # puts "Rebuilding index..."
          new.build
        end

        def rebuild_with_formulas(formulas)
          new.build_with_formulas(formulas)
        end

        def reset_cache
          # Delete the index file to force rebuild on next access
          # This is important for tests to ensure clean state
          FileUtils.rm_f(path)
        end
      end

      # Build index by loading all formulas from disk.
      # Uses Hash-based cache for O(1) lookups during building.
      def build
        with_index_build_cache do
          Formula.all.each do |formula|
            add_formula(formula)
          end
        end

        to_file

        self
      end

      # Build index from pre-loaded formulas.
      # Uses Hash-based cache for O(1) lookups during building.
      #
      # This is the preferred method when formulas are already loaded,
      # as it avoids re-loading from disk.
      def build_with_formulas(formulas)
        with_index_build_cache do
          formulas.each do |formula|
            add_formula(formula)
          end
        end

        to_file

        self
      end

      def add_formula(formula)
        raise unless formula.is_a?(Formula)

        formula.all_fonts.each do |font|
          font.styles.each do |style|
            add_index_formula(style, formula.path)
          end
        end

        entries
      end

      def index_key_for_style(_style)
        raise NotImplementedError,
              "index_key_for_style(style) must be implemented"
      end

      # Add a font style to the index with O(1) or O(n) lookup.
      #
      # Uses `@index_build_cache` Hash for O(1) lookup during building,
      # falling back to O(n) Array lookup for incremental updates.
      def add_index_formula(style, formula_path)
        key = prepare_index_key(style)
        paths = prepare_formula_paths(formula_path)

        return if merge_existing_entry?(key, paths)

        create_and_add_entry(key, paths)
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

      # Yields with a Hash-based lookup cache for O(1) key lookups.
      #
      # This is a performance optimization to avoid O(n²) behavior
      # when building indexes with thousands of entries.
      #
      # @yield [void] Block to execute with cache enabled
      # @return [void]
      def with_index_build_cache
        @index_build_cache = {}
        yield
      ensure
        @index_build_cache = nil
      end

      def prepare_index_key(style)
        key = index_key_for_style(style)
        raise if key.nil? || key.empty?

        normalize_key(key)
      end

      def prepare_formula_paths(formula_path)
        Array(formula_path).map { |p| relative_formula_path(p) }
      end

      # Attempt to merge paths into existing entry.
      # Returns true if merged, false if no existing entry found.
      def merge_existing_entry?(key, paths)
        existing = find_existing_entry(key)
        return false unless existing

        existing.formula_path.concat(paths).uniq!
        true
      end

      # Find existing entry using cache (O(1)) or array scan (O(n))
      def find_existing_entry(key)
        if @index_build_cache
          @index_build_cache[key]
        else
          index_formula(key)
        end
      end

      def create_and_add_entry(key, paths)
        entry = FormulaKeyToPath.new(key: key, formula_path: paths)
        entries << entry
        @index_build_cache[key] = entry if @index_build_cache
      end

      def index_formula(key)
        Array(entries).detect { |f| normalize_key(f.key) == normalize_key(key) }
      end

      def index_formulas(key)
        Array(entries).select { |f| normalize_key(f.key) == normalize_key(key) }
      end

      def relative_formula_path(path)
        escaped = Regexp.escape("#{Fontist.formulas_path}/")
        path.sub(Regexp.new("^#{escaped}"), "")
      end
    end
  end
end
