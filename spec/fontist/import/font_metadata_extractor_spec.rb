require "spec_helper"

RSpec.describe Fontist::Import::FontMetadataExtractor do
  describe "#extract" do
    context "with TrueType font" do
      let(:font_path) { File.join(__dir__, "../../examples/fonts/DejaVuSerif.ttf") }
      let(:extractor) { described_class.new(font_path) }

      it "extracts metadata successfully" do
        metadata = extractor.extract

        expect(metadata).to be_a(Fontist::Import::Models::FontMetadata)
        expect(metadata.family_name).to eq("DejaVu Serif")
        expect(metadata.subfamily_name).to eq("Book")
        expect(metadata.full_name).not_to be_nil
        expect(metadata.postscript_name).not_to be_nil
      end

      it "extracts version without 'Version' prefix" do
        metadata = extractor.extract

        expect(metadata.version).not_to be_nil
        expect(metadata.version).not_to match(/^Version\s+/i)
      end

      it "extracts copyright information" do
        metadata = extractor.extract

        expect(metadata.copyright).not_to be_nil
      end

      it "maps license_description to description" do
        metadata = extractor.extract

        expect(metadata.description).not_to be_nil
      end
    end

    context "with OpenType font" do
      let(:font_path) { File.join(__dir__, "../../examples/fonts/overpass-regular.otf") }
      let(:extractor) { described_class.new(font_path) }

      it "extracts metadata successfully" do
        metadata = extractor.extract

        expect(metadata).to be_a(Fontist::Import::Models::FontMetadata)
        expect(metadata.family_name).not_to be_nil
        expect(metadata.subfamily_name).not_to be_nil
      end

      it "detects font format" do
        metadata = extractor.extract

        expect(metadata.font_format).not_to be_nil
      end
    end

    context "with TrueType Collection" do
      let(:font_path) { File.join(__dir__, "../../examples/fonts/Times.ttc") }
      let(:extractor) { described_class.new(font_path) }

      it "extracts metadata from first font in collection" do
        metadata = extractor.extract

        expect(metadata).to be_a(Fontist::Import::Models::FontMetadata)
        expect(metadata.family_name).not_to be_nil
        expect(metadata.subfamily_name).not_to be_nil
      end
    end

    context "with invalid font file" do
      let(:font_path) { File.join(__dir__, "../../spec_helper.rb") }
      let(:extractor) { described_class.new(font_path) }

      it "raises FontExtractError" do
        expect { extractor.extract }.to raise_error(Fontist::Errors::FontExtractError)
      end
    end

    context "with non-existent file" do
      let(:font_path) { "/tmp/nonexistent_font.ttf" }
      let(:extractor) { described_class.new(font_path) }

      it "raises FontExtractError" do
        expect { extractor.extract }.to raise_error(Fontist::Errors::FontExtractError)
      end
    end
  end
end