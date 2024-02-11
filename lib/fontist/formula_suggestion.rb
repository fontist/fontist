require "fuzzy_match"

module Fontist
  class FormulaSuggestion
    MINIMUM_REQUIRED_SCORE = 0.6

    def initialize
      @fuzzy_match = prepare_search_engine
    end

    def find(name)
      @fuzzy_match.find_all_with_score(normalize(name))
        .tap { |res| Fontist.ui.debug(prettify_result(res)) }
        .select { |_key, score, _| score >= MINIMUM_REQUIRED_SCORE }
        .take(10)
        .map(&:first)
        .map { |x| Formula.find_by_key_or_name(x) }
        .select(&:downloadable?)
    end

    private

    def normalize(name)
      name.gsub(" ", "_")
    end

    def prepare_search_engine
      dict = Formula.all_keys
      stop_words = namespaces(dict).map { |ns| /^#{Regexp.escape(ns)}/i }

      FuzzyMatch.new(dict, stop_words: stop_words)
    end

    def namespaces(keys)
      keys.map do |key|
        parts = key.split("/")
        parts.size
        parts.take(parts.size - 1).join("/")
      end.uniq
    end

    def prettify_result(result)
      list = result.map do |key, dice, leve|
        sprintf(
          "%<dice>.3f %<leve>.3f %<key>s",
          dice: dice,
          leve: leve,
          key: key,
        )
      end

      "FuzzyMatch:\n#{list.join("\n")}"
    end
  end
end
