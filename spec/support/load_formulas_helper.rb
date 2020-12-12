module Fontist
  def self.formulas_repo_path
    Fontist.root_path.join("spec", "fixtures", "formulas")
  end
end

Fontist::Formula.update_formulas_repo
