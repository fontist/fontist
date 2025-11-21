require "spec_helper"
require "fontist/import/google/models/font_family"

RSpec.describe Fontist::Import::Google::Models::FontFamily do
  describe "JSON serialization" do
    let(:static_font_json) do
      {
        "family" => "ABeeZee",
        "variants" => ["regular", "italic"],
        "subsets" => ["latin", "latin-ext"],
        "version" => "v23",
        "lastModified" => "2025-09-08",
        "files" => {
          "regular" => "https://fonts.gstatic.com/s/abeezee/v23/test.ttf",
          "italic" => "https://fonts.gstatic.com/s/abeezee/v23/test-italic.ttf",
        },
        "category" => "sans-serif",
        "kind" => "webfonts#webfont",
        "menu" => "https://fonts.gstatic.com/s/abeezee/v23/menu.ttf",
      }.to_json
    end

    let(:variable_font_json) do
      {
        "family" => "AR One Sans",
        "variants" => ["regular"],
        "subsets" => ["latin"],
        "version" => "v6",
        "lastModified" => "2025-09-08",
        "files" => {
          "regular" => "https://fonts.gstatic.com/s/aronesans/v6/test.ttf",
        },
        "category" => "sans-serif",
        "kind" => "webfonts#webfont",
        "menu" => "https://fonts.gstatic.com/s/aronesans/v6/menu.ttf",
        "axes" => [
          { "tag" => "ARRR", "start" => 10, "end" => 60 },
          { "tag" => "wght", "start" => 400, "end" => 700 },
        ],
      }.to_json
    end

    it "deserializes static font from JSON" do
      family = described_class.from_json(static_font_json)

      expect(family.family).to eq("ABeeZee")
      expect(family.variants).to eq(["regular", "italic"])
      expect(family.subsets).to eq(["latin", "latin-ext"])
      expect(family.version).to eq("v23")
      expect(family.last_modified).to eq("2025-09-08")
      expect(family.category).to eq("sans-serif")
      expect(family.kind).to eq("webfonts#webfont")
      expect(family.menu).to be_a(String)
      expect(family.files).to be_a(Hash)
    end

    it "deserializes variable font with axes from JSON" do
      family = described_class.from_json(variable_font_json)

      expect(family.family).to eq("AR One Sans")
      expect(family.axes).not_to be_nil
      expect(family.axes.length).to eq(2)
      expect(family.axes.first.tag).to eq("ARRR")
      expect(family.axes.last.tag).to eq("wght")
    end

    it "round-trips through JSON serialization" do
      original = described_class.from_json(variable_font_json)
      json = original.to_json
      deserialized = described_class.from_json(json)

      expect(deserialized.family).to eq(original.family)
      expect(deserialized.variants).to eq(original.variants)
      expect(deserialized.axes.length).to eq(original.axes.length)
    end
  end

  describe "#variable_font?" do
    it "returns true when axes are present" do
      family = described_class.new(
        family: "AR One Sans",
        axes: [
          Fontist::Import::Google::Models::Axis.new(
            tag: "wght", start: 100, end: 900
          ),
        ],
      )

      expect(family.variable_font?).to be true
    end

    it "returns false when axes are nil" do
      family = described_class.new(family: "ABeeZee", axes: nil)
      expect(family.variable_font?).to be false
    end

    it "returns false when axes array is empty" do
      family = described_class.new(family: "ABeeZee", axes: [])
      expect(family.variable_font?).to be false
    end
  end

  describe "#variants_by_format" do
    let(:family) do
      described_class.new(
        family: "Test Font",
        files: {
          "regular" => "https://example.com/font.ttf",
          "italic" => "https://example.com/font-italic.ttf",
          "bold" => "https://example.com/font-bold.woff2",
        },
      )
    end

    it "returns TTF variants" do
      ttf_variants = family.variants_by_format(:ttf)

      expect(ttf_variants.keys).to include("regular", "italic")
      expect(ttf_variants.keys).not_to include("bold")
    end

    it "returns WOFF2 variants" do
      woff2_variants = family.variants_by_format(:woff2)

      expect(woff2_variants.keys).to include("bold")
      expect(woff2_variants.keys).not_to include("regular", "italic")
    end

    it "returns empty hash when files is nil" do
      family = described_class.new(family: "Test", files: nil)
      expect(family.variants_by_format(:ttf)).to eq({})
    end
  end

  describe "#axis_by_tag" do
    let(:family) do
      described_class.new(
        family: "Variable Font",
        axes: [
          Fontist::Import::Google::Models::Axis.new(
            tag: "wght", start: 100, end: 900
          ),
          Fontist::Import::Google::Models::Axis.new(
            tag: "wdth", start: 75, end: 125
          ),
        ],
      )
    end

    it "finds axis by tag" do
      axis = family.axis_by_tag("wght")

      expect(axis).not_to be_nil
      expect(axis.tag).to eq("wght")
      expect(axis.start).to eq(100)
    end

    it "returns nil for non-existent tag" do
      axis = family.axis_by_tag("slnt")
      expect(axis).to be_nil
    end

    it "returns nil for static fonts" do
      static_family = described_class.new(family: "Static")
      expect(static_family.axis_by_tag("wght")).to be_nil
    end
  end

  describe "#weight_axes" do
    it "returns all weight axes" do
      family = described_class.new(
        family: "Test",
        axes: [
          Fontist::Import::Google::Models::Axis.new(
            tag: "wght", start: 100, end: 900
          ),
          Fontist::Import::Google::Models::Axis.new(
            tag: "wdth", start: 75, end: 125
          ),
        ],
      )

      weight_axes = family.weight_axes

      expect(weight_axes.length).to eq(1)
      expect(weight_axes.first.tag).to eq("wght")
    end
  end

  describe "#width_axes" do
    it "returns all width axes" do
      family = described_class.new(
        family: "Test",
        axes: [
          Fontist::Import::Google::Models::Axis.new(
            tag: "wght", start: 100, end: 900
          ),
          Fontist::Import::Google::Models::Axis.new(
            tag: "wdth", start: 75, end: 125
          ),
        ],
      )

      width_axes = family.width_axes

      expect(width_axes.length).to eq(1)
      expect(width_axes.first.tag).to eq("wdth")
    end
  end

  describe "#slant_axes" do
    it "returns all slant axes" do
      family = described_class.new(
        family: "Test",
        axes: [
          Fontist::Import::Google::Models::Axis.new(
            tag: "slnt", start: -14, end: 14
          ),
          Fontist::Import::Google::Models::Axis.new(
            tag: "wght", start: 100, end: 900
          ),
        ],
      )

      slant_axes = family.slant_axes

      expect(slant_axes.length).to eq(1)
      expect(slant_axes.first.tag).to eq("slnt")
    end
  end

  describe "#custom_axes" do
    it "returns all custom axes" do
      family = described_class.new(
        family: "Test",
        axes: [
          Fontist::Import::Google::Models::Axis.new(
            tag: "ARRR", start: 10, end: 60
          ),
          Fontist::Import::Google::Models::Axis.new(
            tag: "wght", start: 100, end: 900
          ),
          Fontist::Import::Google::Models::Axis.new(
            tag: "MORF", start: 0, end: 60
          ),
        ],
      )

      custom_axes = family.custom_axes

      expect(custom_axes.length).to eq(2)
      expect(custom_axes.map(&:tag)).to contain_exactly("ARRR", "MORF")
    end
  end

  describe "#axes_count" do
    it "returns number of axes for variable font" do
      family = described_class.new(
        family: "Test",
        axes: [
          Fontist::Import::Google::Models::Axis.new(
            tag: "wght", start: 100, end: 900
          ),
          Fontist::Import::Google::Models::Axis.new(
            tag: "wdth", start: 75, end: 125
          ),
        ],
      )

      expect(family.axes_count).to eq(2)
    end

    it "returns 0 for static font" do
      family = described_class.new(family: "Static")
      expect(family.axes_count).to eq(0)
    end
  end

  describe "#variant_names" do
    it "returns array of variant names" do
      family = described_class.new(
        family: "Test",
        variants: ["regular", "italic", "700"],
      )

      expect(family.variant_names).to eq(["regular", "italic", "700"])
    end

    it "returns empty array when variants is nil" do
      family = described_class.new(family: "Test")
      expect(family.variant_names).to eq([])
    end
  end

  describe "#file_urls" do
    it "returns array of file URLs" do
      family = described_class.new(
        family: "Test",
        files: {
          "regular" => "https://example.com/regular.ttf",
          "italic" => "https://example.com/italic.ttf",
        },
      )

      urls = family.file_urls

      expect(urls.length).to eq(2)
      expect(urls).to include("https://example.com/regular.ttf")
    end

    it "returns empty array when files is nil" do
      family = described_class.new(family: "Test")
      expect(family.file_urls).to eq([])
    end
  end

  describe "#variant_exists?" do
    it "returns true for existing variant" do
      family = described_class.new(
        family: "Test",
        variants: ["regular", "italic"],
      )

      expect(family.variant_exists?("regular")).to be true
    end

    it "returns false for non-existing variant" do
      family = described_class.new(
        family: "Test",
        variants: ["regular", "italic"],
      )

      expect(family.variant_exists?("700")).to be false
    end
  end

  describe "#variant_url" do
    it "returns URL for existing variant" do
      family = described_class.new(
        family: "Test",
        files: {
          "regular" => "https://example.com/regular.ttf",
          "italic" => "https://example.com/italic.ttf",
        },
      )

      expect(family.variant_url("regular")).to eq(
        "https://example.com/regular.ttf"
      )
    end

    it "returns nil for non-existing variant" do
      family = described_class.new(
        family: "Test",
        files: { "regular" => "https://example.com/regular.ttf" },
      )

      expect(family.variant_url("700")).to be_nil
    end
  end

  describe "#summary" do
    it "describes static font" do
      family = described_class.new(
        family: "ABeeZee",
        version: "v23",
      )

      expect(family.summary).to eq("ABeeZee v23")
    end

    it "describes variable font with axes count" do
      family = described_class.new(
        family: "AR One Sans",
        version: "v6",
        axes: [
          Fontist::Import::Google::Models::Axis.new(
            tag: "wght", start: 100, end: 900
          ),
          Fontist::Import::Google::Models::Axis.new(
            tag: "ARRR", start: 10, end: 60
          ),
        ],
      )

      expect(family.summary).to eq("AR One Sans v6 (2 axes)")
    end
  end

  describe "real-world examples from API" do
    it "handles ABeeZee static font" do
      family = described_class.from_json(
        {
          "family" => "ABeeZee",
          "variants" => ["regular", "italic"],
          "subsets" => ["latin", "latin-ext"],
          "version" => "v23",
          "lastModified" => "2025-09-08",
          "files" => {
            "regular" => "https://fonts.gstatic.com/s/abeezee/v23/esDR31xSG-6AGleN6tKukbcHCpE.ttf",
            "italic" => "https://fonts.gstatic.com/s/abeezee/v23/esDT31xSG-6AGleN2tCklZUCGpG-GQ.ttf",
          },
          "category" => "sans-serif",
          "kind" => "webfonts#webfont",
          "menu" => "https://fonts.gstatic.com/s/abeezee/v23/esDR31xSG-6AGleN2tOklQ.ttf",
        }.to_json,
      )

      expect(family.family).to eq("ABeeZee")
      expect(family.variable_font?).to be false
      expect(family.variants.length).to eq(2)
    end

    it "handles AR One Sans variable font" do
      family = described_class.from_json(
        {
          "family" => "AR One Sans",
          "variants" => ["regular"],
          "subsets" => ["latin"],
          "version" => "v6",
          "lastModified" => "2025-09-08",
          "files" => {
            "regular" => "https://fonts.gstatic.com/s/aronesans/v6/TUZ0zwhrmbFp0Srr_tH6fuSaU5EP1H3r.ttf",
          },
          "category" => "sans-serif",
          "kind" => "webfonts#webfont",
          "menu" => "https://fonts.gstatic.com/s/aronesans/v6/menu.ttf",
          "axes" => [
            { "tag" => "ARRR", "start" => 10, "end" => 60 },
            { "tag" => "wght", "start" => 400, "end" => 700 },
          ],
        }.to_json,
      )

      expect(family.family).to eq("AR One Sans")
      expect(family.variable_font?).to be true
      expect(family.axes_count).to eq(2)
      expect(family.custom_axes.length).to eq(1)
      expect(family.weight_axes.length).to eq(1)
    end

    it "handles Advent Pro multi-axis variable font" do
      family = described_class.from_json(
        {
          "family" => "Advent Pro",
          "variants" => ["regular", "italic"],
          "version" => "v33",
          "axes" => [
            { "tag" => "wdth", "start" => 100, "end" => 200 },
            { "tag" => "wght", "start" => 100, "end" => 900 },
          ],
          "files" => {
            "regular" => "https://fonts.gstatic.com/s/adventpro/v33/V8mAoQfxVT4Dvddr_yOwtT2nKb5ZFtI.ttf",
            "italic" => "https://fonts.gstatic.com/s/adventpro/v33/V8mCoQfxVT4Dvddr_yOwhT-tLZxcBtItFw.ttf",
          },
        }.to_json,
      )

      expect(family.variable_font?).to be true
      expect(family.axes_count).to eq(2)
      expect(family.width_axes.length).to eq(1)
      expect(family.weight_axes.length).to eq(1)
    end
  end
end