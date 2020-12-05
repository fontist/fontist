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
  end
end
