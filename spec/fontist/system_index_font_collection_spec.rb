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
  end
end
