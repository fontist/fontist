require "spec_helper"

RSpec.describe Fontist::FontCollection do

  describe ".from_yaml" do
    formula_paths = Dir.glob('spec/examples/formulas/*.yml')

    context "round-trips 'font_collections' of" do
      formula_paths.each do |formula_path|
        context "formula #{formula_path}" do
          content = File.read(formula_path)
          collections = YAML.load(content)["font_collections"]

          # Not all formulas have font collections
          # so we skip those without any.
          next unless collections

          collections.each do |collection|
            it "collection #{collection['name']}" do
              collection_yaml = collection.to_yaml

              expect(described_class.from_yaml(collection_yaml).to_yaml).to eq(collection_yaml)
            end
          end
        end
      end
    end
  end

end
