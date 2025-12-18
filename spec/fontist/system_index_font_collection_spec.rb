require "spec_helper"

RSpec.describe Fontist::SystemIndexFontCollection do
  describe "#from_yaml" do
    context "round-trips" do
      it "round-trips system index file" do
        filename = File.join(Fontist.system_index_path)

        raw_content = File.read(filename)
        content = YAML.safe_load(raw_content)
        # Convert all "content" symbol keys into string keys, "content" is an
        # array with each item a hash here

        content = content.map do |item|
          item.transform_keys(&:to_s)
        end

        collection = described_class.from_yaml(raw_content).tap do |col|
          col.set_path(filename)
          col.set_path_loader(-> { SystemFont.fontist_font_paths })
        end

        expect(collection.to_yaml).to eq(content.to_yaml)
      end
    end
  end
end
