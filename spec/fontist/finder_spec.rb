require "spec_helper"

RSpec.describe Fontist::Finder do
  describe ".copy" do
    context "with valid font name" do
      it "copy fonts in specified directories" do
        name = "DejaVuSerif.ttf"
        dejavu_ttf = Fontist::Finder.copy(name, download_path)

        expect(dejavu_ttf).not_to be_nil
        expect(dejavu_ttf).to include("tmp/#{name}")
      end
    end

    context "with invalid font name" do
      it "raise an missing font error" do
        font_name = "InvalidFont.ttf"

        expect {
          Fontist::Finder.copy(font_name, download_path)
        }.to raise_error(Fontist::Error, "Could not find #{font_name} font")
      end
    end

    context "non writable download paths" do
      it "raise a non writable path message" do
        name = "DejaVuSerif.ttf"
        allow(File).to receive(:writable?).and_return(false)

        expect {
          Fontist::Finder.copy(name, download_path)
        }.to raise_error(Fontist::Error, "No such writable file or directory")
      end
    end
  end

  def download_path
    @download_path ||=(
      temp_path = Fontist.root_path.join("tmp")

      unless File.exist?(temp_path)
        FileUtils.mkdir_p(temp_path)
      end

      temp_path
    )
  end
end
