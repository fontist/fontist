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

  describe ".from_yaml" do
    let(:instance) { described_class.from_yaml(manifest) }

    context "empty manifest" do
      let(:manifest) { {}.to_yaml }

      it "returns empty result" do
        no_fonts do
          expect(instance).to be_empty
        end
      end
    end

    context "manifest given" do
      let(:manifest) { { "Andale Mono" => ["Regular"] }.to_yaml }

      it "deserialize correctly" do
        no_fonts do
          example_font_to_fontist("AndaleMo.TTF")
          expect(instance.first.name).to eq("Andale Mono")
          expect(instance.first.styles).to eq(["Regular"])
        end
      end
    end
  end

  describe "install" do
    describe ".from_hash" do
      include_context "fresh home"
      before { example_formula("andale.yml") }

      let(:instance) { described_class.from_hash(manifest).install }
      let(:manifest) { { "Andale Mono" => "Regular" } }

      context "confirmation option passed" do
        let(:instance) { described_class.from_hash(manifest).install(confirmation: "yes") }

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
        let(:instance) { described_class.from_hash(manifest).install(confirmation: "no") }
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
