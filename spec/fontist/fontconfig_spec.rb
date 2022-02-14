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
        before { example_font("texgyrechorus-mediumitalic.otf") }

        it "fc-match returns installed font", fontconfig: true do
          command
          expect(`fc-match 'texgyrechorus'`).to include("texgyrechorus")
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
          before { example_font("texgyrechorus-mediumitalic.otf") }

          it "fc-match does not return installed font", fontconfig: true do
            command
            expect(`fc-match 'texgyrechorus'`).not_to include("texgyrechorus")
          end
        end
      end
    end
  end
end
