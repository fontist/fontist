require "spec_helper"

RSpec.describe Fontist::Formula do
  describe "#licensed_for_current_platform?" do
    let(:formula) { Fontist::Formula.new }

    context "when platforms is nil" do
      it "returns false" do
        formula.platforms = nil
        expect(formula.licensed_for_current_platform?).to be false
      end
    end

    context "when platforms is empty" do
      it "returns false" do
        formula.platforms = []
        expect(formula.licensed_for_current_platform?).to be false
      end
    end

    context "when current OS matches a platform" do
      it "returns true" do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
        formula.platforms = ["macos"]
        expect(formula.licensed_for_current_platform?).to be true
      end
    end

    context "when current OS matches a prefixed platform" do
      it "returns true" do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
        formula.platforms = ["macos-10.15"]
        expect(formula.licensed_for_current_platform?).to be true
      end
    end

    context "when current OS does not match any platform" do
      it "returns false" do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)
        formula.platforms = ["windows", "macos"]
        expect(formula.licensed_for_current_platform?).to be false
      end
    end
  end

  describe ".from_file" do
    formula_paths = Dir.glob("spec/examples/formulas/*.yml")

    context "round-trips" do
      formula_paths.each do |formula_path|
        it formula_path.to_s do
          content = File.read(formula_path)
          expect(Fontist::Formula.from_yaml(content).to_yaml).to eq(content)
        end
      end
    end
  end

  describe "v5 formula" do
    let(:v5_yaml) { File.read("spec/examples/formulas/roboto_v5.yml") }
    let(:formula) { Fontist::Formula.from_yaml(v5_yaml) }

    it "loads v5 formula correctly" do
      expect(formula.name).to eq("Roboto")
      expect(formula.schema_version).to eq(5)
    end

    it "reports v5? as true" do
      expect(formula.v5?).to be true
    end

    it "returns effective_schema_version of 5" do
      expect(formula.effective_schema_version).to eq(5)
    end

    it "has resources with format metadata" do
      expect(formula.resources).to be_kind_of(Array)
      formats = formula.resources.map(&:format).compact
      expect(formats).to include("ttf", "woff2")
    end

    it "has resources with variable_axes" do
      vf_resource = formula.resources.find { |r| r.variable_axes&.any? }
      expect(vf_resource).not_to be_nil
      expect(vf_resource.variable_axes).to include("wght", "wdth")
    end

    it "has styles with v5 attributes" do
      style = formula.all_fonts.first.styles.first
      expect(style.formats).to include("ttf", "woff2")
      expect(style.variable_font).to eq(false)
    end

    context "matching_resources" do
      it "filters by format" do
        spec = Fontist::FormatSpec.new(format: "woff2")
        matching = formula.matching_resources(spec)
        expect(matching).to all(satisfy { |r| r.format == "woff2" })
        expect(matching.size).to eq(2)
      end

      it "returns all when no constraints" do
        spec = Fontist::FormatSpec.new
        matching = formula.matching_resources(spec)
        expect(matching.size).to eq(formula.resources.size)
      end
    end
  end

  describe ".find" do
    before { Fontist::Index.reset_cache }
    context "by font name" do
      it "returns the font formulas" do
        clear_type = Fontist::Formula.find("Calibri")

        expect(clear_type.fonts.map(&:name)).to include("Calibri")
        expect(clear_type.key).to be
        expect(clear_type.description).to be
      end
    end

    context "for invalid font" do
      it "returns nil to the caller" do
        name = "Calibri Made Up Name"
        formulas = Fontist::Formula.find(name)

        expect(formulas).to be_nil
      end
    end
  end

  describe ".find_fonts" do
    before { Fontist::Index.reset_cache }
    it "returns the exact font names" do
      name = "Andale Mono"
      fonts = Fontist::Formula.find_fonts(name)
      filenames = fonts.map(&:styles).flatten.map(&:font)

      expect(filenames).to include("AndaleMo.TTF")
    end

    it "returns empty array if invalid name provided" do
      name = "Calibri Invlaid"
      fonts = Fontist::Formula.find_fonts(name)

      expect(fonts).to be_empty
    end
  end

  describe ".all" do
    before { Fontist::Index.reset_cache }
    it "returns all registered formulas" do
      formulas = Fontist::Formula.all

      expect(formulas.size).to be > 1
      expect(formulas.first.all_fonts.size).to be > 0
      expect(formulas.first.description).to be_kind_of(String)
    end
  end

  describe "#from_hash" do
    before { Fontist::Index.reset_cache }
    let(:formula) { described_class.from_file(path) }
    let(:path) { Fontist.formulas_path.join("lato.yml").to_s }

    it "fills attributes" do
      expect(formula.key).to eq "lato"
      expect(formula.description).to be_kind_of(String)
      expect(formula.homepage).to be_kind_of(String)
      expect(formula.copyright).to be_kind_of(String)
      expect(formula.license_url).to be_kind_of(String)
      expect(formula.resources).to be_kind_of(Array)
      expect(formula.resources.first).to be_kind_of(Fontist::Resource)
      expect(formula.resources.first.urls.first).to be_kind_of(String)
      expect(formula.all_fonts).to be_kind_of(Array)
      expect(formula.all_fonts.first.name).to be_kind_of(String)
      expect(formula.all_fonts.first.styles).to be_kind_of(Array)
      expect(formula.all_fonts.first.styles.first.type).to be_kind_of(String)
      expect(formula.all_fonts.first.styles.first.font).to be_kind_of(String)
      expect(formula.extract).to be_kind_of(Array)
      expect(formula.extract.first).to be_kind_of(Fontist::Extract) if formula.extract.any?
      expect(formula.license).to be_kind_of(String)
      expect(formula.license_required?).to be false
    end
  end

  describe ".find_by_font_file" do
    before { Fontist::Index.reset_cache }
    it "existing font file" do
      font_path = examples_font_path("ariali.ttf")
      formula = described_class.find_by_font_file(font_path)
      expect(formula).not_to be_nil
    end

    it "missing font file" do
      expect(described_class.find_by_font_file("NonExisting.otf")).to be_nil
    end
  end

  describe ".style_override" do
    before { Fontist::Index.reset_cache }
    it "never nil" do
      formula = described_class.find("Calibri")
      expect(formula.style_override("Calibri")).not_to be_nil
    end
  end

  describe "#name" do
    subject { described_class.find_by_key(key).name }

    include_context "fresh home"

    key_to_name = {
      "andale" => "Andale",
      "google/noto_sans" => "Google/Noto Sans",
      # "noto_sans_cjk" => "Noto Sans CJK", # TODO: implement custom names
    }

    key_to_name.each do |key, name|
      context "#{key}:" do
        let(:key) { key }

        before { example_formula("#{key}.yml") }

        it "=> #{name}" do
          is_expected.to eq name
        end
      end
    end
  end
end
