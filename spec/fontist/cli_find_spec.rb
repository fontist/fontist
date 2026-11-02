require "spec_helper"

RSpec.describe Fontist::CLI do
  describe "find --format" do
    let(:formula) do
      Fontist::Formula.from_yaml(<<~YAML)
        name: Space Mono
        schema_version: 5
        resources:
          woff2_static:
            source: google
            family: Space Mono
            files: ["https://fonts.gstatic.com/space-mono.woff2"]
            format: woff2
        fonts: []
      YAML
    end

    before do
      allow(Fontist::Formula).to receive(:all).and_return([formula])
      allow(Fontist.ui).to receive(:say)
    end

    it "lists fonts in that format without another selector" do
      status = described_class.start(["find", "--format", "woff2", "--json"])

      expect(status).to eq(Fontist::CLI::STATUS_SUCCESS)
      expect(Fontist.ui).to have_received(:say) do |json|
        expect(JSON.parse(json).map { |m| [m["name"], m["format"]] })
          .to eq([["Space Mono", "woff2"]])
      end
    end
  end
end
