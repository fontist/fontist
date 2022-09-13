require "spec_helper"

RSpec.describe Fontist::Manifest::Locations do
  describe ".from_hash" do
    let(:command) { described_class.from_hash(manifest) }

    context "empty manifest" do
      let(:manifest) { {} }

      it "returns empty result" do
        no_fonts do
          expect(command).to be_empty
        end
      end
    end

    context "installed font" do
      let(:manifest) { { "Andale Mono" => ["Regular"] } }

      it "returns its path" do
        no_fonts do
          example_font_to_fontist("AndaleMo.TTF")
          expect(command["Andale Mono"]["Regular"]["paths"]).not_to be_empty
        end
      end
    end

    context "uninstalled font" do
      let(:manifest) { { "Andale Mono" => ["Regular"] } }

      it "returns no path" do
        no_fonts do
          expect { command }.to raise_error Fontist::Errors::MissingFontError
          expect { command }.to(raise_error do |e|
                                  expect(e.font).to eq "Andale Mono"
                                end)
          expect { command }.to(raise_error do |e|
                                  expect(e.style).to eq "Regular"
                                end)
        end
      end
    end

    context "collection font" do
      let(:manifest) { { "Cambria Math" => ["Regular"] } }

      it "returns its full name" do
        no_fonts do
          example_font_to_fontist("CAMBRIA.TTC")
          expect(command["Cambria Math"]["Regular"]["full_name"]).to eq "Cambria Math"
        end
      end
    end

    context "preferred family and no option" do
      let(:manifest) { { "TeXGyreChorus" => nil } }

      it "finds by default family" do
        fresh_fonts_and_formulas do
          example_font("texgyrechorus-mediumitalic.otf")

          expect(command["TeXGyreChorus"]["Regular"]["paths"]).not_to be_empty
        end
      end
    end
  end
end
