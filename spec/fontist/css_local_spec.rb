require "spec_helper"

RSpec.describe Fontist::Css, ".local" do
  let(:font_files) do
    {
      regular: "i7dPIFZifjKcF5UAWdDRUEZ2RFq7AwU",
      italic: "i7dNIFZifjKcF5UAWdDRYER8QHi-EwWMbg",
      bold: "i7dMIFZifjKcF5UAWdDRaPpZYFKQHwyVd3U",
      bold_italic: "i7dSIFZifjKcF5UAWdDRYERE_FeaGy6QZ3WfYg",
    }
  end

  css_it "copies one file per style and writes @font-face rules",
         formulas: %w[space_mono] do
    install_fake_fonts(font_files)
    with_out_dir do |out|
      css_path = described_class.local("Space Mono", output_dir: out,
                                                     url_prefix: "/fonts")

      expect(css_path).to eq(File.join(out, "fonts.css"))
      expect(Dir.children(out).sort).to eq(
        (font_files.values.map { |s| "#{s}.ttf" } + ["fonts.css"]).sort,
      )
      expect(File.read(File.join(out, "#{font_files[:bold]}.ttf")))
        .to eq("FAKE-#{font_files[:bold]}-ttf")
      expect(File.read(css_path)).to eq(<<~CSS)
        @font-face {
          font-family: "Space Mono";
          src: url("/fonts/#{font_files[:regular]}.ttf") format("truetype");
          font-weight: 400;
          font-style: normal;
        }

        @font-face {
          font-family: "Space Mono";
          src: url("/fonts/#{font_files[:bold]}.ttf") format("truetype");
          font-weight: 700;
          font-style: normal;
        }

        @font-face {
          font-family: "Space Mono";
          src: url("/fonts/#{font_files[:italic]}.ttf") format("truetype");
          font-weight: 400;
          font-style: italic;
        }

        @font-face {
          font-family: "Space Mono";
          src: url("/fonts/#{font_files[:bold_italic]}.ttf") format("truetype");
          font-weight: 700;
          font-style: italic;
        }
      CSS
    end
  end

  css_it "writes relative URLs when no prefix is given",
         formulas: %w[space_mono] do
    install_fake_fonts(font_files)
    with_out_dir do |out|
      described_class.local("Space Mono", output_dir: out, styles: "400")

      expect(File.read(File.join(out, "fonts.css")))
        .to include(%{url("#{font_files[:regular]}.ttf")})
    end
  end

  css_it "limits output to the requested styles", formulas: %w[space_mono] do
    install_fake_fonts(font_files)
    with_out_dir do |out|
      described_class.local("Space Mono", output_dir: out, styles: "700i")

      css = File.read(File.join(out, "fonts.css"))
      expect(css.scan("@font-face").size).to eq(1)
      expect(css).to include("font-weight: 700;", "font-style: italic;")
      expect(Dir.children(out).sort)
        .to eq(["fonts.css", "#{font_files[:bold_italic]}.ttf"])
    end
  end

  css_it "escapes quotes in the URL prefix", formulas: %w[space_mono] do
    install_fake_fonts(font_files)
    with_out_dir do |out|
      described_class.local("Space Mono", output_dir: out, styles: "400",
                                          url_prefix: %(/a"b))

      expect(File.read(File.join(out, "fonts.css")))
        .to include(%{url("/a\\"b/#{font_files[:regular]}.ttf")})
    end
  end

  css_it "uses an installed file of the requested --font-format",
         formulas: %w[space_mono] do
    install_fake_fonts(font_files, "woff2")
    with_out_dir do |out|
      described_class.local("Space Mono", output_dir: out, styles: "400",
                                          font_format: "woff2")

      expect(File.read(File.join(out, "fonts.css")))
        .to include(%{url("#{font_files[:regular]}.woff2") format("woff2")})
      expect(Dir.children(out)).to include("#{font_files[:regular]}.woff2")
    end
  end

  css_it "converts an installed font into the requested --font-format",
         formulas: %w[space_mono] do
    ttf = install_fake(font_files[:regular])
    FileUtils.cp(File.expand_path("../examples/fonts/Lato-Heavy.ttf", __dir__),
                 ttf)
    with_out_dir do |out|
      described_class.local("Space Mono", output_dir: out, styles: "400",
                                          font_format: "woff2")

      converted = File.join(out, "#{font_files[:regular]}.woff2")
      expect(File.binread(converted, 4)).to eq("wOF2")
      expect(File.read(File.join(out, "fonts.css")))
        .to include(%{url("#{font_files[:regular]}.woff2") format("woff2")})
    end
  end

  css_it "tells the user to install a font that is not installed",
         formulas: %w[space_mono] do
    with_out_dir do |out|
      expect { described_class.local("Space Mono", output_dir: out) }
        .to raise_error(Fontist::Errors::MissingFontError,
                        /fontist install 'Space Mono'/)
    end
  end

  css_it "rejects an unlisted style", formulas: %w[space_mono] do
    install_fake_fonts(font_files)
    with_out_dir do |out|
      expect do
        described_class.local("Space Mono", output_dir: out, styles: "300")
      end.to raise_error(Fontist::Css::UnavailableStyleError, /'300'/)
    end
  end

  css_it "rejects an unknown family", formulas: %w[space_mono] do
    with_out_dir do |out|
      expect { described_class.local("Nope Sans", output_dir: out) }
        .to raise_error(Fontist::Css::UnknownFamilyError)
    end
  end

  css_it "rejects an unsupported --font-format", formulas: %w[space_mono] do
    with_out_dir do |out|
      expect do
        described_class.local("Space Mono", output_dir: out,
                                            font_format: "eot")
      end.to raise_error(Fontist::Css::InvalidOptionError, /eot/)
    end
  end

  css_it "works through the CLI and prints only the fonts.css path",
         formulas: %w[space_mono] do
    require "fontist/cli"
    install_fake_fonts(font_files)
    with_out_dir do |out|
      expect do
        status = Fontist::CLI.start(["css", "Space Mono", "--local",
                                     "--output-dir", out, "--styles", "400"])
        expect(status).to eq(0)
      end.to output("#{File.join(out, 'fonts.css')}\n").to_stdout
      expect(File.exist?(File.join(out, "#{font_files[:regular]}.ttf")))
        .to be true
    end
  end
end
