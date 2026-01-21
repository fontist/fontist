require "spec_helper"

RSpec.describe Fontist::FontInstaller do
  include_context "fresh home"
  include_context "platform test fonts"
  before { example_formula(test_formula) }

  describe "#install" do
    context "with confirmation" do
      it "installs font" do
        fresh_fonts_and_formulas do
          example_formula_to(test_formula, Fontist.formulas_path)
          formula = Fontist::Formula.find(test_font_downcase)
          paths = described_class.new(formula).install(confirmation: "yes")
          expect(paths).to include(
            include(test_font_file).or(include(test_font_file.downcase)),
          )
          expect(font_files).to include(/#{test_font_file}/i)
        end
      end
    end

    context "with no confirmation" do
      it "raises an licensing error" do
        fresh_fonts_and_formulas do
          example_formula_to(test_formula, Fontist.formulas_path)
          formula = Fontist::Formula.find(test_font_downcase)
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
        skip "Skipped on Windows due to mock/timeout issues" if Fontist::Utils::System.user_os == :windows

        # Use andale formula for mirror testing regardless of platform
        # since we're testing download retry behavior, not font detection
        example_formula("andale.yml")

        # Disable cache to ensure download is attempted
        allow(Fontist).to receive(:use_cache?).and_return(false)

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
         "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/andale32.exe", # rubocop:disable Layout/LineLength
         "http://sft.if.usp.br/msttcorefonts/andale32.exe"]
      end

      let(:command) do
        described_class.new(Fontist::Formula.find("andale mono"))
          .install(confirmation: "yes")
      end

      it "raises the invalid-resource exception" do
        # Use andale formula for mirror testing regardless of platform
        example_formula("andale.yml")

        # Disable cache to ensure download is attempted
        allow(Fontist).to receive(:use_cache?).and_return(false)

        avoid_cache(*mirrors) do
          allow(Down).to receive(:download)
            .with(any_args).and_raise(Down::TimeoutError)

          expect do
            command
          end.to raise_error(Fontist::Errors::InvalidResourceError)
        end
      end
    end

    context "google formula" do
      before { example_formula("source_code_pro.yml") }
      let(:formula) { Fontist::Formula.find_by_key(name) }
      let(:name) { "source_code_pro" }

      context "by formula without font name" do
        it "does not fail and install all fonts" do
          fonts = described_class.new(formula).install(confirmation: "yes")
          expect(fonts.count).to be_positive
        end
      end
    end
  end
end
