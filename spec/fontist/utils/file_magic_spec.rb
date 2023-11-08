require "spec_helper"
require "fontist/utils/file_magic"

RSpec.describe Fontist::Utils::FileMagic do
  describe "#detect" do
    let(:command) { described_class.detect(path) }

    context "ttf" do
      let(:path) { "spec/examples/fonts/Andale Mono.ttf" }

      it "returns ttf type" do
        expect(command).to eq :ttf
      end
    end

    context "otf" do
      let(:path) { "spec/examples/fonts/overpass-regular.otf" }

      it "returns otf type" do
        expect(command).to eq :otf
      end
    end

    context "ttc" do
      let(:path) { "spec/examples/fonts/CAMBRIA.TTC" }

      it "returns ttc type" do
        expect(command).to eq :ttc
      end
    end
  end
end
