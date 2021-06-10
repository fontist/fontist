require "spec_helper"

RSpec.describe Fontist::Index do
  describe ".rebuild_for_main_repo" do
    let(:font_index) do
      Fontist.formulas_repo_path.join("index.yml")
    end

    let(:filename_index) do
      Fontist.formulas_repo_path.join("filename_index.yml")
    end

    context "no private formulas" do
      it "does not raise any error" do
        no_formulas do
          expect { Fontist::Index.rebuild_for_main_repo }.not_to raise_error
        end
      end
    end

    it "rebuils main repo indexes without private formulas" do
      no_formulas do
        formula_repo_with("lato.yml") do |private_repo|
          Fontist::Repo.setup("acme", private_repo)

          Fontist::Index.rebuild_for_main_repo

          expect(YAML.load_file(font_index)).to eq({})
          expect(YAML.load_file(filename_index)).to eq({})
        end
      end
    end
  end
end
