require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::FontconfigCLI do
  describe "#update" do
    let(:command) { described_class.start(["update"]) }
    let(:status) { command }

    context "no fontconfig installed" do
      before do
        allow(Fontist::Fontconfig).to receive(:update)
          .and_raise(Fontist::Errors::FontconfigNotFoundError)
      end

      it "returns fontconfig-not-found error code" do
        expect(Fontist.ui).to receive(:error).with("Could not find fontconfig.")
        expect(status).to be Fontist::CLI::STATUS_FONTCONFIG_NOT_FOUND
      end
    end

    context "with fontconfig installed" do
      it "calls Fontconfig#update" do
        expect(Fontist::Fontconfig).to receive(:update)
        expect(status).to be 0
      end
    end
  end

  describe "#remove" do
    let(:command) { described_class.start(["remove", *options]) }
    let(:options) { [] }
    let(:status) { command }

    context "FontconfigFileNotFoundError is raised" do
      before do
        allow(Fontist::Fontconfig).to receive(:remove)
          .and_raise(Fontist::Errors::FontconfigFileNotFoundError)
      end

      it "prints message" do
        expect(Fontist.ui).to receive(:error)
          .with("Fontist file could not be found in fontconfig configuration.")
        command
      end

      it "returns fontconfig-file-not-found error" do
        expect(status).to eq Fontist::CLI::STATUS_FONTCONFIG_FILE_NOT_FOUND
      end
    end

    context "Fontconfig returns successfully" do
      before { allow(Fontist::Fontconfig).to receive(:remove) }

      it "prints message" do
        expect(Fontist.ui).to receive(:success)
          .with("Fontconfig file has been successfully removed.")
        command
      end

      it "returns success code" do
        expect(status).to eq Fontist::CLI::STATUS_SUCCESS
      end
    end

    context "with force option" do
      let(:options) { ["--force"] }

      it "passes it to Fontconfig" do
        expect(Fontist::Fontconfig).to receive(:remove)
          .with(hash_including(force: true))

        command
      end
    end
  end
end
