module Fontist
  def self.formulas_repo_path
    Fontist.root_path.join("spec", "fixtures", "formulas")
  end
end

Fontist::Formulas.fetch_formulas
Fontist::Formulas.load_formulas
