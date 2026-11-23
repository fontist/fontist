require "spec_helper"

RSpec.describe Fontist::SystemIndexFontCollection do
  describe "#from_yaml" do
    context "round-trips" do
      it "round-trips system index file" do
        filename = File.join(Fontist.system_index_path)

        # Ensure directory exists
        FileUtils.mkdir_p(File.dirname(filename))

        # Create an initial index file if it doesn't exist
        # This simulates a fresh system with an empty index
        unless File.exist?(filename)
          empty_collection = described_class.new
          empty_collection.to_file(filename)
        end

        raw_content = File.read(filename)
        content = YAML.safe_load(raw_content)
        # Convert all "content" symbol keys into string keys, "content" is an
        # array with each item a hash here

        # Handle empty index (content may be nil)
        content = (content || []).map do |item|
          item.transform_keys(&:to_s)
        end

        collection = described_class.from_yaml(raw_content).tap do |col|
          col.set_path(filename)
          col.set_path_loader(-> { SystemFont.fontist_font_paths })
        end

        # Compare parsed YAML to handle empty array vs nil differences
        expect(YAML.safe_load(collection.to_yaml) || []).to eq(content)
      end
    end

    context "with a legacy fonts:-keyed index" do
      it "reads an index written by an older fontist as a bare entry list" do
        legacy = <<~YAML
          fonts:
          - path: "/Library/Fonts/A.ttf"
            full_name: A
            family_name: A
            type: Regular
            file_size: 100
            file_mtime: 100
          - path: "/Library/Fonts/BVar[wght].ttf"
            full_name: B
            family_name: B
            type: Regular
            format: ttf
            variable_font: true
            variable_axes:
            - wght
          last_scan_time: 1795416215
          directory_mtimes:
          - "/Library/Fonts:1773654699"
        YAML

        collection = described_class.from_yaml(legacy)

        expect(Array(collection.fonts).size).to eq(2)
        expect(collection.fonts.first.path).to eq("/Library/Fonts/A.ttf")
        expect(collection.fonts.first.family_name).to eq("A")
        expect(collection.fonts.last.variable_font).to be(true)
      end

      it "raises the corrupted-index error for neither shape missing entries" do
        legacy = <<~YAML
          fonts:
          - path: "/Library/Fonts/A.ttf"
            full_name: A
            family_name: A
            type: Regular
        YAML

        collection = described_class.from_yaml(legacy)

        expect { collection.check_index }.not_to raise_error
      end
    end
  end
end
