module Fontist
  module Css
    # Finds the Google formula for a family name and its canonical
    # Google Fonts family (Resource#family; never derived from a slug).
    module GoogleFamily
      class << self
        # @return [Array(Formula, String)] formula and canonical family
        def resolve(family)
          name = family.to_s.strip
          matches = google_matches(candidates(name), name)
          raise NotGoogleFamilyError, name if matches.empty?

          keys = matches.map { |formula, _| formula.key }
          raise AmbiguousFamilyError.new(name, keys) if keys.uniq.size > 1

          matches.first
        end

        private

        def candidates(name)
          formulas = name.empty? ? [] : Formula.find_many(name)
          raise UnknownFamilyError, name if formulas.empty?

          formulas
        end

        def google_matches(formulas, name)
          formulas.filter_map do |formula|
            canonical = canonical_family(formula, name)
            [formula, canonical] if canonical
          end
        end

        def canonical_family(formula, name)
          wanted = normalize(name)
          Array(formula.resources).each do |resource|
            next unless resource.source == "google"
            return resource.family if normalize(resource.family) == wanted
          end
          nil
        end

        def normalize(text)
          text.to_s.downcase.gsub(/[\s_-]+/, " ")
        end
      end
    end
  end
end
