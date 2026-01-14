require "spec_helper"

RSpec.describe Fontist::Indexes::FontistIndex do
  subject(:index) { described_class.instance }

  # Initialize the collection before each test to ensure @collection exists
  # This is needed because the collection is lazily initialized
  before { index.collection }

  describe "singleton behavior" do
    it "returns the same instance" do
      expect(described_class.instance).to be(index)
    end

    it "is a singleton" do
      expect(index).to be_a(described_class)
    end
  end

  describe "#find" do
    context "when fonts exist" do
      it "delegates to collection" do
        expect(index.instance_variable_get(:@collection)).to receive(:find)
          .with("Roboto", "Regular")
          .and_return([])

        index.find("Roboto", "Regular")
      end

      it "works without style parameter" do
        expect(index.instance_variable_get(:@collection)).to receive(:find)
          .with("Arial", nil)
          .and_return([])

        index.find("Arial")
      end
    end

    context "when fonts don't exist" do
      it "returns nil" do
        allow(index.instance_variable_get(:@collection)).to receive(:find).and_return(nil)

        expect(index.find("NonExistent")).to be_nil
      end
    end
  end

  describe "#font_exists?" do
    let(:mock_font) { double("font", path: "/test/path/font.ttf") }

    before do
      collection = index.instance_variable_get(:@collection)
      allow(collection).to receive(:fonts).and_return([mock_font])
    end

    it "returns true when font path matches" do
      expect(index.font_exists?("/test/path/font.ttf")).to be true
    end

    it "returns false when font path doesn't match" do
      expect(index.font_exists?("/other/path/font.ttf")).to be false
    end

    it "works with empty font list" do
      collection = index.instance_variable_get(:@collection)
      allow(collection).to receive(:fonts).and_return([])

      expect(index.font_exists?("/any/path/font.ttf")).to be false
    end
  end

  describe "#add_font" do
    it "resets verification flag" do
      collection = index.instance_variable_get(:@collection)
      expect(collection).to receive(:reset_verification!)
      allow(collection).to receive(:build)

      index.add_font("/test/path/font.ttf")
    end

    it "rebuilds index" do
      collection = index.instance_variable_get(:@collection)
      allow(collection).to receive(:reset_verification!)
      expect(collection).to receive(:build).with(forced: true, verbose: false)

      index.add_font("/test/path/font.ttf")
    end
  end

  describe "#remove_font" do
    let(:mock_font1) { double("font1", path: "/test/path/font1.ttf") }
    let(:mock_font2) { double("font2", path: "/test/path/font2.ttf") }
    let(:fonts) { [mock_font1, mock_font2] }

    before do
      collection = index.instance_variable_get(:@collection)
      allow(collection).to receive(:fonts).and_return(fonts)
    end

    it "removes font with matching path" do
      collection = index.instance_variable_get(:@collection)
      expect(collection).to receive(:to_file).with(Fontist.fontist_index_path)

      index.remove_font("/test/path/font1.ttf")

      expect(fonts).to eq([mock_font2])
    end

    it "saves index file after removal" do
      collection = index.instance_variable_get(:@collection)
      expect(collection).to receive(:to_file).with(Fontist.fontist_index_path)

      index.remove_font("/test/path/font1.ttf")
    end

    it "doesn't remove non-matching paths" do
      collection = index.instance_variable_get(:@collection)
      allow(collection).to receive(:to_file)

      index.remove_font("/nonexistent/font.ttf")

      expect(fonts).to eq([mock_font1, mock_font2])
    end
  end

  describe "#rebuild" do
    it "delegates to collection rebuild" do
      collection = index.instance_variable_get(:@collection)
      expect(collection).to receive(:rebuild).with(verbose: false)

      index.rebuild
    end

    it "passes verbose flag" do
      collection = index.instance_variable_get(:@collection)
      expect(collection).to receive(:rebuild).with(verbose: true)

      index.rebuild(verbose: true)
    end
  end

  describe "integration with Fontist paths" do
    it "uses correct index path" do
      expect(Fontist.fontist_index_path.to_s).to include("fontist_index")
    end

    it "scans fontist fonts directory" do
      # This is a private method but we can verify the pattern it uses
      expect(Fontist.fonts_path.to_s).to include("fonts")
    end
  end
end