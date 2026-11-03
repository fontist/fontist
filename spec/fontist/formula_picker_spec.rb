require "spec_helper"

RSpec.describe Fontist::FormulaPicker do
  describe ".call" do
    context "size above the limit, but cached" do
      include_context "fresh home"

      before { example_formula("georgia.yml") }

      let(:formula_path) { Fontist.formulas_path.join("georgia.yml") }
      let(:formula) { Fontist::Formula.from_file(formula_path) }

      it "don't raises size-limit error if cached" do
        cache = double

        expect(cache).to receive(:already_fetched?).and_return(true)
        allow(Fontist::Utils::Cache).to receive(:new).and_return(cache)

        picker = Fontist::FormulaPicker.new(
          "Georgia",
          size_limit: 0,
          version: nil,
          smallest: nil,
          newest: nil,
        )
        picker.call([formula])
      end
    end

    context "with a format constraint" do
      let(:archive_formula) do
        Fontist::Formula.from_yaml(<<~YAML)
          name: Lato
          schema_version: 5
          resources:
            lato.zip:
              urls: ["https://example.com/lato.zip"]
          fonts:
          - name: Lato
            styles:
            - family_name: Lato
              type: Regular
              full_name: Lato Regular
              font: Lato-Regular.ttf
        YAML
      end

      let(:google_formula) do
        Fontist::Formula.from_yaml(<<~YAML)
          name: Lato
          schema_version: 5
          resources:
            woff2_static:
              source: google
              family: Lato
              files: ["https://fonts.gstatic.com/lato-regular.woff2"]
              format: woff2
          fonts:
          - name: Lato
            styles:
            - family_name: Lato
              type: Regular
              full_name: Lato Regular
              font: lato-regular.woff2
              formats: [woff2]
        YAML
      end

      let(:ttf_formula) do
        Fontist::Formula.from_yaml(<<~YAML)
          name: Lato
          schema_version: 5
          resources:
            lato-ttf.zip:
              urls: ["https://example.com/lato-ttf.zip"]
              format: ttf
          fonts:
          - name: Lato
            styles:
            - family_name: Lato
              type: Regular
              full_name: Lato Regular
              font: Lato-Regular.ttf
              formats: [ttf]
        YAML
      end

      let(:formulas) { [archive_formula, google_formula] }
      let(:format_spec) { Fontist::FormatSpec.new(format: "woff2") }

      subject(:picked) do
        described_class.new("Lato", format_spec: format_spec).call(formulas)
      end

      it "picks the formula that offers the requested format" do
        expect(picked.map { |f| f.resources.map(&:format) }).to eq([["woff2"]])
      end

      context "when the format is only in an archive's file names" do
        let(:format_spec) { Fontist::FormatSpec.new(format: "ttf") }

        it "picks the archive" do
          expect(picked.map { |f| f.resources.map(&:name) })
            .to eq([["lato.zip"]])
        end
      end

      context "when no formula offers the format" do
        let(:formulas) { [ttf_formula] }

        it "leaves conversion to the installer" do
          expect(picked.map { |f| f.resources.map(&:name) })
            .to eq([["lato-ttf.zip"]])
        end
      end

      context "when a variable font is requested and none exists" do
        let(:formulas) { [archive_formula] }
        let(:format_spec) do
          Fontist::FormatSpec.new(format: "ttf", prefer_variable: true)
        end

        it "raises format not available" do
          expect { picked }
            .to raise_error(Fontist::Errors::FormatNotAvailableError)
        end
      end
    end
  end
end
