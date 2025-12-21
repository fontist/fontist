# frozen_string_literal: true

require "spec_helper"
require "unibuf"
require "fontist/import/google/metadata_adapter"
require "fontist/import/google/models/metadata"

RSpec.describe Fontist::Import::Google::MetadataAdapter do
  describe ".adapt" do
    context "with simple font (ABeeZee)" do
      let(:file_path) do
        File.expand_path("../../../fixtures/google_fonts/abeezee/METADATA.pb",
                         __dir__)
      end
      let(:unibuf_message) { Unibuf.parse_textproto_file(file_path) }
      let(:metadata) { described_class.adapt(unibuf_message) }

      it "converts to Metadata model" do
        expect(metadata).to be_a(Fontist::Import::Google::Models::Metadata)
      end

      it "extracts basic fields" do
        expect(metadata.name).to eq("ABeeZee")
        expect(metadata.designer).to eq("Anja Meiners")
        expect(metadata.license).to eq("OFL")
        expect(metadata.category).to eq("SANS_SERIF")
        expect(metadata.date_added).to eq("2012-09-30")
      end

      it "extracts font files" do
        expect(metadata.font_count).to eq(2)
        expect(metadata.regular_font).not_to be_nil
        expect(metadata.regular_font.filename).to eq("ABeeZee-Regular.ttf")
      end

      it "extracts subsets" do
        expect(metadata.subsets).to include("latin", "latin-ext", "menu")
      end

      it "extracts source information" do
        expect(metadata.source).not_to be_nil
        expect(metadata.source.repository_url).to eq("https://github.com/googlefonts/abeezee")
      end

      it "has no axes (static font)" do
        expect(metadata.variable_font?).to be false
        expect(metadata.axis_count).to eq(0)
      end
    end

    context "with variable font (Alexandria)" do
      let(:file_path) do
        File.expand_path(
          "../../../fixtures/google_fonts/alexandria/METADATA.pb", __dir__
        )
      end
      let(:unibuf_message) { Unibuf.parse_textproto_file(file_path) }
      let(:metadata) { described_class.adapt(unibuf_message) }

      it "extracts variable font axes" do
        expect(metadata.variable_font?).to be true
        expect(metadata.axis_count).to eq(1)
        expect(metadata.axis_tags).to eq(["wght"])
      end

      it "extracts axis details" do
        wght_axis = metadata.weight_axis
        expect(wght_axis).not_to be_nil
        expect(wght_axis.min_value).to eq(100.0)
        expect(wght_axis.max_value).to eq(900.0)
      end

      it "extracts primary_script" do
        expect(metadata.primary_script).to eq("Arab")
      end
    end

    context "with complex variable font (Roboto Flex)" do
      let(:file_path) do
        File.expand_path(
          "../../../fixtures/google_fonts/robotoflex/METADATA.pb", __dir__
        )
      end
      let(:unibuf_message) { Unibuf.parse_textproto_file(file_path) }
      let(:metadata) { described_class.adapt(unibuf_message) }

      it "extracts all 13 axes" do
        expect(metadata.axis_count).to eq(13)
        expect(metadata.axis_tags).to include("GRAD", "XOPQ", "XTRA", "YOPQ", "YTAS",
                                              "YTDE", "YTFI", "YTLC", "YTUC", "opsz",
                                              "slnt", "wdth", "wght")
      end

      it "extracts registry_default_overrides correctly" do
        expect(metadata.has_registry_overrides?).to be true
        expect(metadata.registry_override("XOPQ")).to eq(96.0)
        expect(metadata.registry_override("YTDE")).to eq(-203.0)
        expect(metadata.registry_override("XTRA")).to eq(468.0)
      end

      it "extracts source with archive_url" do
        expect(metadata.source.archive_url).to eq("https://github.com/googlefonts/roboto-flex/releases/download/3.200/roboto-flex-fonts.zip")
      end
    end

    context "with large file (Noto Sans)" do
      let(:file_path) do
        File.expand_path("../../../fixtures/google_fonts/notosans/METADATA.pb",
                         __dir__)
      end
      let(:unibuf_message) { Unibuf.parse_textproto_file(file_path) }
      let(:metadata) { described_class.adapt(unibuf_message) }

      it "extracts multiple font files" do
        expect(metadata.font_count).to eq(2)
        expect(metadata.has_italics?).to be true
      end

      it "extracts many languages" do
        expect(metadata.language_count).to be > 800
        expect(metadata.languages).to include("aa_Latn")
      end

      it "identifies as Noto font" do
        expect(metadata.noto_font?).to be true
      end
    end
  end
end
