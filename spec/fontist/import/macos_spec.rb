require "spec_helper"

RSpec.describe "Fontist::Import::Macos", slow: true, dev: true do
  include_context "fresh home"
  before(:context) { require "fontist/import/macos" }
  let(:name) { "macos_version.yml" }
  let(:options) do
    { name: "macOS version",
      fonts_link: "https://support.apple.com/en-om/HT211240#download" }
  end

  it "generates formula with necessary attributes" do
    allow_any_instance_of(Fontist::Import::Macos).to(receive(:fetch_links)
      .and_wrap_original { |m, *args| m.call(*args).take(5) })

    Fontist::Import::Macos.new(options).call

    formula = YAML.load_file(Fontist.formulas_path.join("macos", name))
    expect(formula).to include("description", "homepage", "instructions")
    expect(formula["platforms"].first).to start_with("macos-")
    expect(formula).to include("font_collections").or include("fonts")
  end
end
