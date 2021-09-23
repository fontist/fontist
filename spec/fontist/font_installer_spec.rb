require "spec_helper"

RSpec.describe Fontist::FontInstaller do
  include_context "fresh home"
  before { example_formula("andale.yml") }

  describe "#install" do
    context "with confirmation" do
      it "installs font" do
        no_fonts do
          formula = Fontist::Formula.find("andale mono")
          paths = described_class.new(formula).install(confirmation: "yes")
          expect(paths).to include(
            include("AndaleMo.TTF").or(include("andalemo.ttf")),
          )
          expect(font_files).to include(/AndaleMo.TTF/i)
        end
      end
    end

    context "with no confirmation" do
      it "raises an licensing error" do
        no_fonts do
          formula = Fontist::Formula.find("andale mono")
          expect { described_class.new(formula).install(confirmation: "no") }
            .to raise_error(Fontist::Errors::LicensingError)
        end
      end
    end

    context "first mirror fails" do
      let(:first_mirror) do
        "https://gitlab.com/fontmirror/archive/-/raw/master/andale32.exe"
      end

      let(:second_mirror) do
        "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/andale32.exe"
      end

      let(:command) do
        described_class.new(Fontist::Formula.find("andale mono"))
          .install(confirmation: "yes")
      end

      it "tries the second one" do
        avoid_cache(first_mirror) do
          allow(Down).to receive(:download)
            .with(any_args).and_call_original
          expect(Down).to receive(:download)
            .with(first_mirror, any_args).and_raise(Down::NotFound, "not found")
            .at_least(3).times

          allow(Fontist::Utils::Downloader).to receive(:download)
            .with(any_args).and_call_original
          expect(Fontist::Utils::Downloader).to receive(:download)
            .with(second_mirror, any_args).and_call_original

          command
        end
      end
    end

    context "all mirrors fail" do
      let(:mirrors) do
        ["https://gitlab.com/fontmirror/archive/-/raw/master/andale32.exe",
         "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/andale32.exe", # rubocop:disable Metrics/LineLength
         "http://sft.if.usp.br/msttcorefonts/andale32.exe"]
      end

      let(:command) do
        described_class.new(Fontist::Formula.find("andale mono"))
          .install(confirmation: "yes")
      end

      it "raises the invalid-resource exception" do
        avoid_cache(*mirrors) do
          allow(Down).to receive(:download)
            .with(any_args).and_raise(Down::TimeoutError)

          expect do
            command
          end.to raise_error(Fontist::Errors::InvalidResourceError)
        end
      end
    end
  end
end
