require "spec_helper"

RSpec.describe "Fontist::Import::Macos", slow: true, dev: true do
  include_context "fresh home"
  before(:context) { require "fontist/import/macos" }

  it "generates formula with necessary attributes" do
    allow_any_instance_of(Fontist::Import::Macos).to(receive(:links)
      .and_wrap_original { |m, *args| m.call(*args).take(5) })

    formulas_path_pattern = Fontist.formulas_path.join("macos", "*")
    expect(Dir.glob(formulas_path_pattern)).to be_empty

    Fontist::Import::Macos.new.call

    expect(Dir.glob(formulas_path_pattern).size).to eq 5

    formula = YAML.load_file(Dir.glob(formulas_path_pattern).first)
    expect(formula).to include("description", "homepage", "resources")
    expect(formula["platforms"].first).to eq "macos"
    expect(formula).to include("font_collections").or include("fonts")
  end
end
