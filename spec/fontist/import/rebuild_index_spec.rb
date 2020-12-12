require "spec_helper"
require "fontist/import/rebuild_index"

RSpec.describe Fontist::Import::RebuildIndex do
  let(:command) { Fontist::Import::RebuildIndex.new.call }
  let(:index) { YAML.load_file(Fontist.formula_index_path) }

  context "repo has a formula with fonts" do
    before do
      tmp = create_tmp_dir
      allow(Fontist).to receive(:formulas_repo_path).and_return(Pathname.new(tmp))
      formulas_dir = File.join(tmp, "Formulas")
      FileUtils.mkdir(formulas_dir)
      FileUtils.cp("spec/examples/formulas/lato.yml", formulas_dir)
    end

    it "build an index with fonts, styles and a path to formula" do
      command
      expect(index).to include("Lato" => include("Black" => ["lato.yml"],
                                                 "Bold" => ["lato.yml"]))
    end
  end
end
