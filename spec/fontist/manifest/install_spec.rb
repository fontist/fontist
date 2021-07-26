require "spec_helper"

RSpec.describe Fontist::Manifest::Install do
  describe ".from_hash" do
    include_context "fresh home"
    before { example_formula("andale.yml") }

    let(:command) { described_class.from_hash(manifest) }
    let(:manifest) { { "Andale Mono" => "Regular" } }

    context "confirmation option passed" do
      let(:command) { described_class.from_hash(manifest, confirmation: "yes") }

      it "accepts it with no error" do
        expect { command }.not_to raise_error
      end
    end

    context "unsupported font" do
      let(:manifest) { { "Non-existing Font" => ["Regular"] } }

      it "raises non-supported font error" do
        expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
        expect { command }.to(
          raise_error { |e| expect(e.font).to eq "Non-existing Font" },
        )
      end
    end

    context "requires license confirmation and no flag passed" do
      before { stub_license_agreement_prompt_with("no") }

      it "raises licensing error" do
        expect { command }.to raise_error Fontist::Errors::LicensingError
      end
    end

    context "confirmation option passed as no and nil input is returned" do
      let(:command) { described_class.from_hash(manifest, confirmation: "no") }
      before { stub_license_agreement_prompt_with(nil) }

      it "raises licensing error" do
        expect { command }.to raise_error Fontist::Errors::LicensingError
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
      let(:manifest) { { "Lato Heavy" => nil } }
      before { example_formula("lato.yml") }

      it "installs by default family" do
        expect { command }.not_to raise_error
      end
    end
  end
end
