require "spec_helper"

RSpec.describe Fontist::Utils::Dsl::Font do
  describe ".new" do
    context "with missing required attribute" do
      let(:attrs) { { not_required_attribute: "value" } }

      it "raises exception" do
        expect { described_class.new(attrs) }
          .to raise_error(Fontist::Errors::MissingAttributeError)
      end
    end
  end

  describe "#attributes" do
    let(:attrs) do
      { family_name: "Demo Family",
        style: "Regular",
        full_name: "Demo Family Regular",
        filename: "Demo-Regular.ttf" }
    end

    it "returns attributes hash" do
      attributes = described_class.new(attrs).attributes

      expect(attributes).to include(family_name: "Demo Family",
                                    type: "Regular",
                                    full_name: "Demo Family Regular",
                                    font: "Demo-Regular.ttf")
    end
  end
end
