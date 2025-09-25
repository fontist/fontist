require "spec_helper"

RSpec.describe Fontist::SystemIndexFontCollection do

  describe "#from_yaml" do
    context "round-trips" do
      filename = File.join(Fontist.system_index_path, "fontist_index.default_family.yml")

      it "#{filename}" do
        raw_content = IO.read(filename)
        content = YAML.load(raw_content)
        # Convert all "content" symbol keys into string keys, "content" is an
        # array with each item a hash here

        content = content.map do |item|
          item.each_with_object({}) do |(key, value), result|
            result[key.to_s] = value
          end
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
