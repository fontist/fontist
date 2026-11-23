require "spec_helper"
require "fontist/format_spec"

RSpec.describe Fontist::FormatSpec do
  describe ".from_options" do
    it "creates FormatSpec from options hash" do
      spec = described_class.from_options(
        format: "woff2",
        variable_axes: "wght,wdth",
        prefer_variable: true,
      )

      expect(spec.format).to eq("woff2")
      expect(spec.variable_axes).to contain_exactly("wght", "wdth")
      expect(spec.prefer_variable).to be true
    end

    it "handles nil options" do
      spec = described_class.from_options({})

      expect(spec.format).to be_nil
      expect(spec.prefer_variable).to be false
    end

    it "parses comma-separated variable_axes" do
      spec = described_class.from_options(variable_axes: "wght, wdth, ital")

      expect(spec.variable_axes).to contain_exactly("wght", "wdth", "ital")
    end

    it "handles array variable_axes" do
      spec = described_class.from_options(variable_axes: ["wght", "wdth"])

      expect(spec.variable_axes).to contain_exactly("wght", "wdth")
    end

    it "handles nil variable_axes" do
      spec = described_class.from_options(variable_axes: nil)

      expect(spec.variable_axes).to be_nil.or eq([])
    end

    it "sets default keep_original to true" do
      spec = described_class.from_options({})

      expect(spec.keep_original).to be true
    end

    it "allows overriding keep_original" do
      spec = described_class.from_options(keep_original: false)

      expect(spec.keep_original).to be false
    end
  end

  describe ".parse_variable_axes" do
    it "returns nil for nil input" do
      expect(described_class.parse_variable_axes(nil)).to be_nil
    end

    it "returns array for array input" do
      expect(described_class.parse_variable_axes(["wght", "wdth"]))
        .to contain_exactly("wght", "wdth")
    end

    it "parses comma-separated string" do
      expect(described_class.parse_variable_axes("wght,wdth,ital"))
        .to contain_exactly("wght", "wdth", "ital")
    end

    it "strips whitespace from parsed values" do
      expect(described_class.parse_variable_axes("wght, wdth , ital"))
        .to contain_exactly("wght", "wdth", "ital")
    end
  end

  describe "#has_constraints?" do
    it "returns false with no constraints" do
      spec = described_class.new

      result = spec.has_constraints?
      # Could be false or nil depending on Lutaml::Model behavior
      expect([false, nil]).to include(result)
    end

    it "returns true with format" do
      spec = described_class.new(format: "woff2")

      expect(spec.has_constraints?).to be true
    end

    it "returns true with variable_axes" do
      spec = described_class.new(variable_axes: ["wght"])

      expect(spec.has_constraints?).to be true
    end

    it "returns true with prefer_variable" do
      spec = described_class.new(prefer_variable: true)

      expect(spec.has_constraints?).to be true
    end

    it "returns true with prefer_format" do
      spec = described_class.new(prefer_format: "woff2")

      expect(spec.has_constraints?).to be true
    end
  end

  describe "#variable_requested?" do
    it "returns false with no variable options" do
      spec = described_class.new

      result = spec.variable_requested?
      expect([false, nil]).to include(result)
    end

    it "returns true with variable_axes" do
      spec = described_class.new(variable_axes: ["wght"])

      expect(spec.variable_requested?).to be true
    end

    it "returns true with prefer_variable" do
      spec = described_class.new(prefer_variable: true)

      expect(spec.variable_requested?).to be true
    end
  end

  describe "#axes" do
    it "returns empty array when variable_axes is nil" do
      spec = described_class.new

      expect(spec.axes).to eq([])
    end

    it "returns variable_axes as array" do
      spec = described_class.new(variable_axes: ["wght", "wdth"])

      expect(spec.axes).to contain_exactly("wght", "wdth")
    end
  end

  describe "#needs_transcode?" do
    it "returns false when format is nil" do
      spec = described_class.new

      expect(spec.needs_transcode?(%w[ttf otf])).to be false
    end

    it "returns false when format is available" do
      spec = described_class.new(format: "woff2")

      expect(spec.needs_transcode?(%w[ttf woff2 otf])).to be false
    end

    it "returns true when format is not available" do
      spec = described_class.new(format: "woff2")

      expect(spec.needs_transcode?(%w[ttf otf])).to be true
    end
  end

  describe "#specific_collection_index?" do
    it "returns false when collection_index is nil" do
      spec = described_class.new

      expect(spec.specific_collection_index?).to be false
    end

    it "returns true when collection_index is set" do
      spec = described_class.new(collection_index: 0)

      expect(spec.specific_collection_index?).to be true
    end
  end

  describe "attributes" do
    it "allows setting format" do
      spec = described_class.new(format: "ttf")

      expect(spec.format).to eq("ttf")
    end

    it "allows setting transcode_path" do
      spec = described_class.new(transcode_path: "/tmp/fonts")

      expect(spec.transcode_path).to eq("/tmp/fonts")
    end

    it "allows setting collection_index" do
      spec = described_class.new(collection_index: 2)

      expect(spec.collection_index).to eq(2)
    end
  end

  describe "font operation options" do
    it "reads subset and fallback options" do
      spec = described_class.from_options(
        subset_unicodes: "U+0041", subset_text: "ab",
        fallback_to_original: true
      )

      expect(spec.subset_requested?).to be true
      expect(spec.fallback_to_original).to be true
    end

    it "reads the instance option" do
      spec = described_class.from_options(instance: "wght=300")

      expect(spec.instance_requested?).to be true
      expect(spec.instance_coordinates).to eq("wght" => 300.0)
      expect(described_class.from_options({}).instance_requested?).to be false
    end

    it "defaults to no subset and no fallback" do
      spec = described_class.from_options({})

      expect(spec.subset_requested?).to be false
      expect(spec.fallback_to_original).to be false
    end

    it "does not treat a subset as a format constraint" do
      spec = described_class.from_options(subset_text: "ab")

      expect(spec.has_constraints?).to be false
    end
  end

  describe "static/variable preference" do
    it "defaults to no preference" do
      spec = described_class.new

      expect(spec.variable).to be_nil
      expect(spec.static_requested?).to be false
      expect(spec.variable_requested?).to be false
      expect(spec.all_variants).to be false
    end

    it "records an explicit static request" do
      spec = described_class.new(variable: false)

      expect(spec.static_requested?).to be true
      expect(spec.variable_requested?).to be false
      expect(spec.has_constraints?).to be true
    end

    it "records an explicit variable request" do
      spec = described_class.new(variable: true)

      expect(spec.variable_requested?).to be true
      expect(spec.has_constraints?).to be true
    end

    it "records an all-variants request" do
      spec = described_class.new(all_variants: true)

      expect(spec.variable).to be_nil
      expect(spec.static_requested?).to be false
      expect(spec.variable_requested?).to be false
      expect(spec.has_constraints?).to be true
    end

    describe ".from_options" do
      it "maps the --static flag" do
        spec = described_class.from_options(static: true)

        expect(spec.variable).to be false
        expect(spec.has_constraints?).to be true
      end

      it "maps the --variable flag" do
        spec = described_class.from_options(variable: true)

        expect(spec.variable).to be true
      end

      it "maps the --both flag" do
        spec = described_class.from_options(both: true)

        expect(spec.all_variants).to be true
        expect(spec.has_constraints?).to be true
      end

      it "keeps prefer_variable as a variable request" do
        spec = described_class.from_options(prefer_variable: true)

        expect(spec.variable_requested?).to be true
      end

      it "lets explicit flags win over prefer_variable" do
        spec = described_class.from_options(prefer_variable: true, static: true)

        expect(spec.static_requested?).to be true
        expect(spec.variable_requested?).to be false
      end
    end
  end
end
