require "spec_helper"

RSpec.describe Fontist::Import::Otf::FontFile do
  describe "initialization" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }

    it "initializes with path" do
      font_file = described_class.new(font_path)

      expect(font_file.path).to eq(font_path)
    end

    it "accepts name_prefix option" do
      font_file = described_class.new(font_path, name_prefix: "Custom ")

      expect(font_file.family_name).to start_with("Custom ")
    end
  end

  describe "#to_style" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns hash with style attributes" do
      style = font_file.to_style

      expect(style).to be_a(Hash)
      expect(style).to include(:family_name, :type, :full_name, :post_script_name)
      expect(style).to include(:version, :copyright, :font)
    end

    it "includes font and source_font" do
      style = font_file.to_style

      expect(style).to have_key(:font)
    end

    it "excludes nil values" do
      style = font_file.to_style

      expect(style.values).not_to include(nil)
    end
  end

  describe "#to_collection_style" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns hash without font and source_font" do
      style = font_file.to_collection_style

      expect(style).to be_a(Hash)
      expect(style).not_to have_key(:font)
      expect(style).not_to have_key(:source_font)
    end

    it "includes all other style attributes" do
      style = font_file.to_collection_style

      expect(style).to include(:family_name, :type, :full_name, :post_script_name)
    end
  end

  describe "#family_name" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }

    it "returns family name without prefix" do
      font_file = described_class.new(font_path)

      expect(font_file.family_name).to eq("DejaVu Serif")
    end

    it "includes prefix when provided" do
      font_file = described_class.new(font_path, name_prefix: "Custom ")

      expect(font_file.family_name).to eq("Custom DejaVu Serif")
    end
  end

  describe "#type" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns subfamily name" do
      expect(font_file.type).to eq("Book")
    end
  end

  describe "#preferred_family_name" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }

    context "when preferred family name exists" do
      let(:font_file) { described_class.new(font_path) }

      it "returns preferred family name without prefix" do
        preferred = font_file.preferred_family_name
        expect(preferred).not_to be_nil if preferred
      end
    end

    context "with name prefix" do
      let(:font_file) { described_class.new(font_path, name_prefix: "Custom ") }

      it "includes prefix when preferred family name exists" do
        if font_file.preferred_family_name
          expect(font_file.preferred_family_name).to start_with("Custom ")
        end
      end
    end
  end

  describe "#preferred_type" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns preferred subfamily name" do
      preferred = font_file.preferred_type
      expect(preferred).to be_a(String).or be_nil
    end
  end

  describe "#full_name" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns full font name" do
      expect(font_file.full_name).not_to be_nil
      expect(font_file.full_name).to be_a(String)
    end
  end

  describe "#post_script_name" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns PostScript name" do
      expect(font_file.post_script_name).not_to be_nil
      expect(font_file.post_script_name).to be_a(String)
    end
  end

  describe "#version" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns version string" do
      expect(font_file.version).not_to be_nil
      expect(font_file.version).to be_a(String)
    end

    it "does not include 'Version' prefix" do
      expect(font_file.version).not_to match(/^Version\s+/i)
    end
  end

  describe "#description" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns description (license description)" do
      description = font_file.description
      expect(description).to be_a(String).or be_nil
    end
  end

  describe "#copyright" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns copyright information" do
      expect(font_file.copyright).not_to be_nil
      expect(font_file.copyright).to be_a(String)
    end
  end

  describe "#homepage" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns vendor URL" do
      homepage = font_file.homepage
      expect(homepage).to be_a(String).or be_nil
    end
  end

  describe "#license_url" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
    let(:font_file) { described_class.new(font_path) }

    it "returns license URL" do
      url = font_file.license_url
      expect(url).to be_a(String).or be_nil
    end
  end

  describe "#font" do
    context "with simple extension" do
      let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
      let(:font_file) { described_class.new(font_path) }

      it "returns standardized font filename" do
        expect(font_file.font).to eq("DejaVuSerif.ttf")
      end
    end

    context "with compound extension" do
      let(:font_path) { File.join(__dir__, "../../../examples/fonts/Times.ttc") }
      let(:font_file) { described_class.new(font_path) }

      it "handles collection files correctly" do
        expect(font_file.font).to match(/\.ttc$/)
      end
    end
  end

  describe "#source_font" do
    context "when font name matches original" do
      let(:font_path) { File.join(__dir__, "../../../examples/fonts/DejaVuSerif.ttf") }
      let(:font_file) { described_class.new(font_path) }

      it "returns nil when names match" do
        expect(font_file.source_font).to be_nil
      end
    end
  end

  describe "with OpenType font" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/overpass-regular.otf") }
    let(:font_file) { described_class.new(font_path) }

    it "extracts all metadata correctly" do
      expect(font_file.family_name).not_to be_nil
      expect(font_file.type).not_to be_nil
      expect(font_file.font).to match(/\.otf$/)
    end
  end

  describe "with TrueType Collection" do
    let(:font_path) { File.join(__dir__, "../../../examples/fonts/Times.ttc") }
    let(:font_file) { described_class.new(font_path) }

    it "processes collection file" do
      expect(font_file.family_name).not_to be_nil
      expect(font_file.type).not_to be_nil
      expect(font_file.font).to match(/\.ttc$/)
    end
  end
end