require "spec_helper"

RSpec.describe Fontist::Manifest::Install do
  describe ".from_hash" do
    let(:command) { described_class.from_hash(manifest) }
    let(:manifest) { {} }

    context "confirmation option passed" do
      let(:command) { described_class.from_hash(manifest, confirmation: "yes") }

      it "accepts it with no error" do
        expect { command }.not_to raise_error
      end
    end

    context "unsupported font" do
      let(:manifest) { { "Unexisting Font" => ["Regular"] } }

      it "raises non-supported font error" do
        no_fonts do
          expect { command }.to raise_error Fontist::Errors::NonSupportedFontError
        end
      end
    end

    context "requires license confirmation and no flag passed" do
      before { stub_license_agreement_prompt_with("no") }

      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "raises licensing error" do
        no_fonts do
          expect { command }.to raise_error Fontist::Errors::LicensingError
        end
      end
    end
  end
end