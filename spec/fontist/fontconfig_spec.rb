require "spec_helper"

RSpec.describe Fontist::Fontconfig do
  include_context "fresh home"

  around do |example|
    Dir.mktmpdir do |dir|
      ENV["XDG_CONFIG_HOME"] = @xdg_config_home = dir
      example.run
      ENV["XDG_CONFIG_HOME"] = @xdg_config_home = nil
    end
  end

  let(:config_path) do
    File.join(@xdg_config_home, "fontconfig", "conf.d", "10-fontist.conf")
  end

  let(:font_filename) { "texgyrechorus-mediumitalic.otf" }

  let(:installed_font_path) do
    Fontist.fonts_path.join("tex_gyre_chorus", font_filename).to_s
  end

  shared_context "no fontconfig installed" do
    before { allow(Fontist::Helpers).to receive(:run).and_raise(Errno::ENOENT) }
  end

  shared_context "with fontconfig" do
    before { allow(Fontist::Helpers).to receive(:run).and_return("") }
  end

  shared_examples "fc-cache regenerator" do
    it "calls fc-cache -f" do
      expect(Fontist::Helpers).to receive(:run).with("fc-cache -f")
      command
    end
  end

  describe "#update" do
    let(:command) { described_class.new.update }

    context "no fontconfig installed" do
      include_context "no fontconfig installed"

      it "fails with FontconfigNotFoundError" do
        expect { command }
          .to raise_error(Fontist::Errors::FontconfigNotFoundError)
      end
    end

    context "with fontconfig" do
      include_context "with fontconfig"

      include_examples "fc-cache regenerator"

      context "no fontist file exists in fontconfig configuration" do
        it "creates fontist file" do
          command
          expect(Pathname.new(config_path)).to exist
        end
      end

      context "some font installed" do
        before { example_font(font_filename) }

        # Verifies what Fontconfig#update actually controls: writing the
        # XDG config and rebuilding the cache so fontconfig discovers the
        # font. The before/after pair proves command did the work — without
        # it, fc-list would still show the font on fontconfig 2.17 by
        # auto-scanning a configured dir, masking a missing fc-cache call.
        # We assert via fc-list rather than fc-match because fc-match's
        # selection is influenced by system-wide configs (e.g. fontconfig
        # 2.18's 05-macos.conf adds macOS asset directories) and may
        # prefer a higher-coverage system font over our single-style test
        # font even on an exact family query. We match on the full
        # installed path (not just family or filename) because TeX
        # distributions ship the same family AND the same filename — only
        # the per-test mktmpdir prefix is uniquely ours.
        it "registers font with fontconfig", fontconfig: true do
          allow(Fontist::Helpers).to receive(:run)
            .with("fc-cache -f").and_call_original
          # Precondition: no XDG config exists yet, fontconfig has no
          # way to discover the font in our temp fonts_path.
          expect(`fc-list :family='TeX Gyre Chorus'`)
            .not_to include(installed_font_path)
          command
          expect(`fc-list :family='TeX Gyre Chorus'`)
            .to include(installed_font_path)
        end
      end
    end
  end

  describe "#remove" do
    let(:command) { described_class.new(options).remove }
    let(:options) { {} }

    context "no fontist file exist" do
      it "raises file-not-found error" do
        expect { command }
          .to raise_error(Fontist::Errors::FontconfigFileNotFoundError)
      end

      context "with force option" do
        let(:options) { { force: true } }

        it "proceeds with no error" do
          expect { command }.not_to raise_error
        end
      end
    end

    context "fontist file exists in fontconfig configuration" do
      before do
        FileUtils.mkdir_p(File.dirname(config_path))
        File.write(config_path, config_content)
      end

      let(:config_content) do
        <<~CONTENT
          <?xml version='1.0'?>
          <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
          <fontconfig>
            <dir>#{Fontist.fonts_path}</dir>
          </fontconfig>
        CONTENT
      end

      context "no fontconfig installed" do
        include_context "no fontconfig installed"

        it "removes the file" do
          command
          expect(Pathname.new(config_path)).not_to exist
        end
      end

      context "with fontconfig" do
        include_context "with fontconfig"

        include_examples "fc-cache regenerator"

        context "some font installed" do
          before { example_font(font_filename) }

          # See note on the matching update example for why fc-list (not
          # fc-match) and why we assert on the full installed path. The
          # precondition (font is visible) relies on fontconfig's
          # auto-scan of the <dir> element written to config_path by the
          # enclosing before block, which already names Fontist.fonts_path
          # — so no explicit fc-cache seed is needed. Auto-scan is a
          # hazard for the #update example (it can mask a missing
          # fc-cache call), but here it's load-bearing in the opposite
          # direction: the postcondition still has to prove command makes
          # the font invisible.
          it "unregisters font from fontconfig", fontconfig: true do
            allow(Fontist::Helpers).to receive(:run)
              .with("fc-cache -f").and_call_original
            expect(`fc-list :family='TeX Gyre Chorus'`)
              .to include(installed_font_path)
            command
            expect(`fc-list :family='TeX Gyre Chorus'`)
              .not_to include(installed_font_path)
          end
        end
      end
    end
  end
end
