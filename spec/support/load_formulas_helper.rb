module Fontist
  class << self
    alias_method :orig_default_fontist_path, :default_fontist_path
    def default_fontist_path
      Fontist.root_path.join("spec", "fixtures")
    end

    # Reuse cached downloads
    def downloads_path
      orig_default_fontist_path.join("downloads")
    end
  end
end

Fontist::Formula.update_formulas_repo
