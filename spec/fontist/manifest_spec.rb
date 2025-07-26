require "spec_helper"

RSpec.describe Fontist::Manifest do
  describe "parsing" do
    let(:manifest_path) { "spec/examples/manifests/mscorefonts.yml" }
    it "round-trips" do
      content = "---\n" + File.read(manifest_path).split("---\n").last
      manifest = described_class.from_yaml(content)
      expect(manifest.to_yaml).to eq(content)
    end
  end

  describe ".from_hash" do
    let(:instance) { described_class.from_yaml(manifest) }

    context "empty manifest" do
      let(:manifest) { {}.to_yaml }

      it "returns empty result" do
        no_fonts do
          expect(instance).to be_empty
        end
      end
    end

    context "installed font" do
      let(:manifest) { { "Andale Mono" => ["Regular"] }.to_yaml }

      it "returns its path" do
        no_fonts do
          example_font_to_fontist("AndaleMo.TTF")
          puts "*"*30
          puts instance.inspect

          expect(instance["Andale Mono"]["Regular"]["paths"]).not_to be_empty
        end
      end
    end

    context "not installed font" do
      let(:manifest) { { "Andale Mono" => ["Regular"] }.to_yaml }

      it "returns no path" do
        no_fonts do
          expect { instance }.to raise_error Fontist::Errors::MissingFontError
          expect { instance }.to(raise_error { |e| expect(e.font).to eq "Andale Mono" })
          expect { instance }.to(raise_error { |e| expect(e.style).to eq "Regular" })
        end
      end
    end

    context "collection font" do
      let(:manifest) { { "Cambria Math" => ["Regular"] }.to_yaml }

      it "returns its full name" do
        no_fonts do
          example_font_to_fontist("CAMBRIA.TTC")
          expect(instance["Cambria Math"]["Regular"]["full_name"]).to eq "Cambria Math"
        end
      end
    end

    context "preferred family and no option" do
      let(:manifest) { { "TeXGyreChorus" => nil } }

      it "finds by default family" do
        fresh_fonts_and_formulas do
          example_font("texgyrechorus-mediumitalic.otf")

          expect(instance["TeXGyreChorus"]["Regular"]["paths"]).not_to be_empty
        end
      end
    end
  end

  describe "install" do
    describe ".from_hash" do
      include_context "fresh home"
      before { example_formula("andale.yml") }

      let(:instance) { described_class.from_hash(manifest) }
      let(:manifest) { { "Andale Mono" => "Regular" } }

      context "confirmation option passed" do
        let(:instance) { described_class.from_hash(manifest, confirmation: "yes") }

        it "accepts it with no error" do
          expect { instance }.not_to raise_error
        end
      end

      context "unsupported font" do
        let(:manifest) { { "Non-existing Font" => ["Regular"] } }

        it "raises non-supported font error" do
          expect { instance }.to raise_error Fontist::Errors::UnsupportedFontError
          expect { instance }.to(
            raise_error { |e| expect(e.font).to eq "Non-existing Font" },
          )
        end
      end

      context "requires license confirmation and no flag passed" do
        before { stub_license_agreement_prompt_with("no") }

        it "raises licensing error" do
          expect { instance }.to raise_error Fontist::Errors::LicensingError
        end
      end

      context "confirmation option passed as no and nil input is returned" do
        let(:instance) { described_class.from_hash(manifest, confirmation: "no") }
        before { stub_license_agreement_prompt_with(nil) }

        it "raises licensing error" do
          expect { instance }.to raise_error Fontist::Errors::LicensingError
        end
      end

      context "no_progress option passed" do
        it "accepts it with no error" do
          expect do
            described_class.from_hash(manifest,
                                      no_progress: true,
                                      confirmation: "yes")
          end.not_to raise_error
        end
      end

      context "preferred family and no option" do
        let(:manifest) { { "TeXGyreChorus" => nil } }
        before { example_formula("tex_gyre_chorus.yml") }

        it "installs by default family" do
          expect { instance }.not_to raise_error
        end
      end
    end
  end

end
