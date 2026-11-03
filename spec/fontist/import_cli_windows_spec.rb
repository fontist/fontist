require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::ImportCLI do
  describe "windows" do
    it "writes a v5 formula for each Windows font extension pack" do
      Dir.mktmpdir do |dir|
        allow(Fontist.ui).to receive(:say)

        status = described_class.start(["windows", "--output-path", dir])

        formulas = Dir.glob(File.join(dir, "*.yml"))
          .map { |path| Fontist::Formula.from_file(path) }
        expect(status).to eq(Fontist::CLI::STATUS_SUCCESS)
        expect(formulas.size)
          .to eq(Fontist::WindowsFodMetadata.all_capabilities.size)
        expect(formulas.map { |f| [f.schema_version, f.platforms] }.uniq)
          .to eq([[5, ["windows"]]])
        keys = formulas.map { |f| "#{f.name.downcase.tr(' ', '_')}.yml" }
        expect(Dir.children(dir).sort).to eq(keys.sort)
      end
    end
  end
end
