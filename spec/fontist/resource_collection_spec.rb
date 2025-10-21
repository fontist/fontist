require "spec_helper"

RSpec.describe Fontist::ResourceCollection do

  describe ".from_yaml" do
    formula_paths = Dir.glob('spec/examples/formulas/*.yml')

    context "round-trips 'resources' of" do
      formula_paths.each do |formula_path|
        it "formula #{formula_path}" do
          content = File.read(formula_path)
          content = YAML.load(content)["resources"].to_yaml
          expect(described_class.from_yaml(content).to_yaml).to eq(content)
        end
      end
    end
  end

end
