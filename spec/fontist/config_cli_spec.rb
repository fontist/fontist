require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::ConfigCLI do
  include_context "fresh home"

  after(:context) do
    restore_default_settings
  end

  describe "#show" do
    let(:command) { described_class.start(["show"]) }

    context "no custom values set" do
      it "prints that config is empty" do
        expect(Fontist.ui).to receive(:success).with("Config is empty.")
        command
      end
    end
  end

  describe "#set" do
    let(:command) { described_class.start(["set", key, value]) }

    context "non-existent value" do
      let(:key) { "non-existent" }
      let(:value) { "v" }

      it "returns non-existent-attribute status and prints error message" do
        expect(Fontist.ui)
          .to receive(:error).with("No such attribute 'non-existent' exists.")

        command
      end
    end
  end

  describe "#keys" do
    it "prints all available keys with their defaults" do
      expect(Fontist.ui).to receive(:say).with("Available keys:")
      expect(Fontist.ui).to receive(:say).with(start_with("fonts_path"))
      expect(Fontist.ui).to receive(:say).with("open_timeout (default: 60)")
      expect(Fontist.ui).to receive(:say).with("read_timeout (default: 60)")

      described_class.start(["keys"])
    end
  end
end
