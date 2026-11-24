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

    context "when formula is licensed for current platform" do
      it "skips license check even without confirmation" do
        fresh_fonts_and_formulas do
          example_formula_to(test_formula, Fontist.formulas_path)
          formula = Fontist::Formula.find(test_font_downcase)
          allow(formula).to receive(:license_required?).and_return(true)
          allow(formula).to receive(:licensed_for_current_platform?).and_return(true)

          expect do
            described_class.new(formula).install(confirmation: "no")
          end.not_to raise_error
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

  describe "per-style resource resolution (google static/variable)" do
    let(:formula_yaml) do
      <<~YAML
        name: work_sans
        schema_version: 5
        resources:
          ttf_variable:
            source: google
            family: Work Sans
            files:
            - https://raw.githubusercontent.com/google/fonts/abc/ofl/worksans/WorkSans[wght].ttf
            - https://raw.githubusercontent.com/google/fonts/abc/ofl/worksans/WorkSans-Italic[wght].ttf
            urls:
            - https://raw.githubusercontent.com/google/fonts/abc/ofl/worksans/WorkSans[wght].ttf
            - https://raw.githubusercontent.com/google/fonts/abc/ofl/worksans/WorkSans-Italic[wght].ttf
            format: ttf
            variable_axes: [wght]
          ttf_static:
            source: google
            family: Work Sans
            files:
            - https://fonts.gstatic.com/s/worksans/v24/black-regular.ttf
            - https://fonts.gstatic.com/s/worksans/v24/black-italic.ttf
            - https://fonts.gstatic.com/s/worksans/v24/regular.ttf
            urls:
            - https://fonts.gstatic.com/s/worksans/v24/black-regular.ttf
            - https://fonts.gstatic.com/s/worksans/v24/black-italic.ttf
            - https://fonts.gstatic.com/s/worksans/v24/regular.ttf
            format: ttf
        fonts:
        - name: Work Sans Black
          styles:
          - family_name: Work Sans Black
            type: Regular
            font: WorkSans-Black.ttf
            source_font: black-regular.ttf
            formats: [ttf]
            variable_font: false
            source_resource: ttf_static
          - family_name: Work Sans Black
            type: Italic
            font: WorkSans-BlackItalic.ttf
            source_font: black-italic.ttf
            formats: [ttf]
            variable_font: false
            source_resource: ttf_static
        - name: Work Sans
          styles:
          - family_name: Work Sans
            type: Regular
            font: WorkSans-Regular.ttf
            source_font: regular.ttf
            formats: [ttf]
            variable_font: false
            source_resource: ttf_static
          - family_name: Work Sans
            type: Regular
            font: WorkSans[wght].ttf
            formats: [ttf]
            variable_font: true
            variable_axes: [wght]
            source_resource: ttf_variable
      YAML
    end

    let(:formula) { Fontist::Formula.from_yaml(formula_yaml) }

    def installer_for(font_name, format_spec = nil)
      described_class.new(formula, font_name: font_name,
                          format_spec: format_spec)
    end

    let(:download_dir) { Dir.mktmpdir }
    let(:fake_download_class) { Struct.new(:path) }

    def fake_download(url)
      path = File.join(download_dir, File.basename(url.to_s))
      File.write(path, "fake font bytes")
      fake_download_class.new(path)
    end

    describe "#style_resource_groups" do
      it "maps static styles to their named resource" do
        groups = installer_for("Work Sans Black").send(:style_resource_groups)

        expect(groups.map(&:first).map(&:name)).to eq(%w[ttf_static])
        expect(groups.first.last.map(&:font))
          .to eq(%w[WorkSans-Black.ttf WorkSans-BlackItalic.ttf])
      end

      it "splits mixed static/variable styles across resources" do
        spec = Fontist::FormatSpec.new(all_variants: true)
        groups = installer_for("Work Sans", spec).send(:style_resource_groups)
        by_resource = groups.to_h { |resource, styles| [resource.name, styles] }

        expect(by_resource["ttf_static"].map(&:font))
          .to eq(%w[WorkSans-Regular.ttf])
        expect(by_resource["ttf_variable"].map(&:font))
          .to eq(%w[WorkSans[wght].ttf])
      end

      it "keeps only static styles when static is requested" do
        spec = Fontist::FormatSpec.new(variable: false)
        groups = installer_for("Work Sans", spec).send(:style_resource_groups)

        expect(groups.map(&:first).map(&:name)).to eq(%w[ttf_static])
      end

      it "keeps only variable styles when variable is requested" do
        spec = Fontist::FormatSpec.new(variable: true)
        groups = installer_for("Work Sans", spec).send(:style_resource_groups)

        expect(groups.map(&:first).map(&:name)).to eq(%w[ttf_variable])
      end

      it "keeps both kinds when all_variants is requested" do
        spec = Fontist::FormatSpec.new(all_variants: true)
        groups = installer_for("Work Sans", spec).send(:style_resource_groups)
        by_resource = groups.to_h { |resource, styles| [resource.name, styles] }

        expect(by_resource["ttf_static"].map(&:font))
          .to eq(%w[WorkSans-Regular.ttf])
        expect(by_resource["ttf_variable"].map(&:font))
          .to eq(%w[WorkSans[wght].ttf])
      end

      it "prefers static styles for the base family when no preference is given" do
        groups = installer_for("Work Sans").send(:style_resource_groups)
        all_styles = groups.flat_map(&:last)

        expect(all_styles.map(&:variable_font?)).to all(be(false))
      end

      it "resolves styles by file membership when source_resource is missing" do
        legacy = Fontist::Formula.from_yaml(formula_yaml.sub(
          /      source_resource: ttf_static\n/, ""
        ))
        groups = described_class.new(legacy, font_name: "Work Sans Black")
          .send(:style_resource_groups)

        expect(groups.map(&:first).map(&:name)).to eq(%w[ttf_static])
      end
    end

    describe "#install" do
      it "downloads only the requested static files, never the variable ones" do
        downloaded = []
        allow(Fontist::Utils::Downloader).to receive(:download) do |url, *|
          downloaded << url.to_s
          fake_download(url)
        end

        paths = installer_for("Work Sans Black").install(confirmation: "yes")

        expect(downloaded).to contain_exactly(
          "https://fonts.gstatic.com/s/worksans/v24/black-regular.ttf",
          "https://fonts.gstatic.com/s/worksans/v24/black-italic.ttf",
        )
        expect(paths.map { |p| File.basename(p) })
          .to contain_exactly("WorkSans-Black.ttf", "WorkSans-BlackItalic.ttf")
      end

      it "installs each style from its own resource for an all-variants request" do
        spec = Fontist::FormatSpec.new(all_variants: true)
        downloaded = []
        allow(Fontist::Utils::Downloader).to receive(:download) do |url, *|
          downloaded << url.to_s
          fake_download(url)
        end

        installer_for("Work Sans", spec).install(confirmation: "yes")

        expect(downloaded).to contain_exactly(
          "https://fonts.gstatic.com/s/worksans/v24/regular.ttf",
          "https://raw.githubusercontent.com/google/fonts/abc/ofl/worksans/WorkSans[wght].ttf",
        )
      end

      it "warns instead of silently dropping styles whose file is missing" do
        broken = Fontist::Formula.from_yaml(formula_yaml.sub(
          "source_font: black-italic.ttf", "source_font: gone-italic.ttf"
        ))
        allow(Fontist::Utils::Downloader).to receive(:download) do |url, *|
          fake_download(url)
        end
        allow(Fontist.ui).to receive(:warn)

        described_class.new(broken, font_name: "Work Sans Black")
          .install(confirmation: "yes")

        expect(Fontist.ui).to have_received(:warn)
          .with(/gone-italic\.ttf/)
      end
    end
  end
end
