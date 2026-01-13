require "spec_helper"

RSpec.describe Fontist::InstallLocations::FontistLocation do
  let(:formula) do
    instance_double(Fontist::Formula, key: "roboto")
  end

  let(:location) { described_class.new(formula) }

  describe "#location_type" do
    it "returns :fontist" do
      expect(location.location_type).to eq(:fontist)
    end
  end

  describe "#base_path" do
    it "returns formula-keyed path under fonts directory" do
      path = location.base_path
      
      expect(path.to_s).to include("fonts/roboto")
      expect(path).to be_a(Pathname)
    end

    it "isolates different formulas" do
      formula1 = instance_double(Fontist::Formula, key: "vendor1/roboto")
      formula2 = instance_double(Fontist::Formula, key: "vendor2/roboto")
      
      location1 = described_class.new(formula1)
      location2 = described_class.new(formula2)
      
      expect(location1.base_path).not_to eq(location2.base_path)
      expect(location1.base_path.to_s).to include("vendor1/roboto")
      expect(location2.base_path.to_s).to include("vendor2/roboto")
    end

    it "handles complex formula keys" do
      complex_formula = instance_double(Fontist::Formula, key: "google/noto/sans")
      location = described_class.new(complex_formula)
      
      expect(location.base_path.to_s).to include("google/noto/sans")
    end
  end

  describe "#managed_location?" do
    it "always returns true" do
      expect(location.send(:managed_location?)).to be true
    end
  end

  describe "#requires_elevated_permissions?" do
    it "returns false" do
      expect(location.requires_elevated_permissions?).to be false
    end
  end

  describe "#permission_warning" do
    it "returns nil" do
      expect(location.permission_warning).to be_nil
    end
  end

  describe "#index" do
    it "returns FontistIndex singleton instance" do
      index = location.send(:index)
      
      expect(index).to be_a(Fontist::Indexes::FontistIndex)
      expect(index).to eq(Fontist::Indexes::FontistIndex.instance)
    end

    it "returns same instance on multiple calls" do
      index1 = location.send(:index)
      index2 = location.send(:index)
      
      expect(index1).to be(index2)
    end
  end

  describe "integration with Fontist.fonts_path" do
    it "uses Fontist.fonts_path as root" do
      expect(location.base_path.to_s).to start_with(Fontist.fonts_path.to_s)
    end
  end
end