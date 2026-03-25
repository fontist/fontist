RSpec.describe Fontist do
  it "has a version number" do
    expect(Fontist::VERSION).not_to be nil
  end

  describe "path methods return Pathname objects" do
    it "returns Pathname for fontist_path" do
      expect(Fontist.fontist_path).to be_a(Pathname)
    end

    it "returns Pathname for root_path" do
      expect(Fontist.root_path).to be_a(Pathname)
    end

    it "returns Pathname for default_fontist_path" do
      expect(Fontist.default_fontist_path).to be_a(Pathname)
    end
  end
end
