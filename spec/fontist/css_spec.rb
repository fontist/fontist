require "spec_helper"

RSpec.describe Fontist::Css do
  let(:base) { "https://fonts.googleapis.com/css2?family=" }

  describe ".url" do
    css_it "pins Source Code Pro with sorted upright and italic tuples" do
      url = described_class.url("Source Code Pro",
                                styles: %w[600i 300 700 300i 600])
      expect(url).to eq(
        "#{base}Source+Code+Pro:ital,wght@0,300;0,600;0,700;1,300;1,600" \
        "&display=swap",
      )
    end

    css_it "pins Space Mono without the ital axis when nothing is italic" do
      expect(described_class.url("Space Mono", styles: "700,400")).to eq(
        "#{base}Space+Mono:wght@400;700&display=swap",
      )
    end

    css_it "pins Space Mono with italics" do
      url = described_class.url("Space Mono", styles: "400,400i,700,700i")
      expect(url).to eq(
        "#{base}Space+Mono:ital,wght@0,400;0,700;1,400;1,700&display=swap",
      )
    end

    css_it "pins Lato including Hairline and Black weights" do
      url = described_class.url("Lato", styles: "900,100,400i")
      expect(url).to eq(
        "#{base}Lato:ital,wght@0,100;0,900;1,400&display=swap",
      )
    end

    css_it "pins Source Sans 3 with the canonical Google family name" do
      url = described_class.url("Source Sans 3", styles: "300,300i,600,600i")
      expect(url).to eq(
        "#{base}Source+Sans+3:ital,wght@0,300;0,600;1,300;1,600&display=swap",
      )
    end

    css_it "pins Roboto variable font weights from the listed styles" do
      url = described_class.url("Roboto", styles: "100,500,900,900i")
      expect(url).to eq(
        "#{base}Roboto:ital,wght@0,100;0,500;0,900;1,900&display=swap",
      )
    end

    css_it "accepts comma separated styles in one string" do
      expect(described_class.url("Lato", styles: "300,700"))
        .to eq("#{base}Lato:wght@300;700&display=swap")
    end

    css_it "removes duplicate styles" do
      expect(described_class.url("Lato", styles: %w[700 300 700 300]))
        .to eq("#{base}Lato:wght@300;700&display=swap")
    end

    css_it "omits the axis spec when no styles are requested" do
      expect(described_class.url("Lato"))
        .to eq("#{base}Lato&display=swap")
    end

    css_it "matches the family case-insensitively and keeps Google's name" do
      expect(described_class.url("source sans 3", styles: "400"))
        .to eq("#{base}Source+Sans+3:wght@400&display=swap")
    end

    css_it "uses the requested display value" do
      expect(described_class.url("Lato", display: "optional"))
        .to eq("#{base}Lato&display=optional")
    end

    css_it "never produces the malformed '600i=swap' form" do
      url = described_class.url("Source Sans 3", styles: "600,600i")
      expect(url).not_to include("i=swap")
      expect(url).to end_with("&display=swap")
    end

    css_it "does no network access" do
      expect(Fontist::Utils::Downloader).not_to receive(:download)
      described_class.url("Lato", styles: "400")
    end
  end

  describe ".url errors" do
    css_it "rejects the malformed style '600i=swap'" do
      expect { described_class.url("Lato", styles: "600i=swap") }
        .to raise_error(Fontist::Css::InvalidStyleError, /600i=swap/)
    end

    css_it "rejects a weight outside 100..900" do
      expect { described_class.url("Lato", styles: "950") }
        .to raise_error(Fontist::Css::InvalidStyleError, /950/)
    end

    css_it "rejects a style the formula does not list and names the options" do
      expect { described_class.url("Space Mono", styles: "300") }
        .to raise_error(Fontist::Css::UnavailableStyleError,
                        /'300'.*Space Mono.*400, 700, 400i, 700i/)
    end

    css_it "rejects an unavailable italic" do
      expect { described_class.url("Space Mono", styles: "500i") }
        .to raise_error(Fontist::Css::UnavailableStyleError, /500i/)
    end

    css_it "rejects an invalid display value" do
      expect { described_class.url("Lato", display: "soon") }
        .to raise_error(Fontist::Css::InvalidDisplayError, /soon.*swap/)
    end

    css_it "rejects an unknown family" do
      expect { described_class.url("Nonexistent Family") }
        .to raise_error(Fontist::Css::UnknownFamilyError, /Nonexistent Family/)
    end

    css_it "does not rename Source Sans Pro to Source Sans 3" do
      expect { described_class.url("Source Sans Pro") }
        .to raise_error(Fontist::Css::UnknownFamilyError, /Source Sans Pro/)
    end

    css_it "rejects a blank family" do
      expect { described_class.url(" ") }
        .to raise_error(Fontist::Css::UnknownFamilyError)
    end

    css_it "rejects a family that is not a Google family" do
      expect { described_class.url("Andale Mono") }
        .to raise_error(Fontist::Css::NotGoogleFamilyError, /Andale Mono/)
    end

    css_it "rejects a family served by several Google formulas" do
      copy = Fontist.formulas_path.join("google", "space_mono_copy.yml")
      FileUtils.cp(Fontist.formulas_path.join("google", "space_mono.yml"), copy)
      Fontist::Index.rebuild

      expect { described_class.url("Space Mono") }
        .to raise_error(Fontist::Css::AmbiguousFamilyError,
                        /several Google formulas.*space_mono/)
    end
  end

  describe ".link" do
    let(:expected_href) do
      "#{base}Space+Mono:wght@400;700&amp;display=swap"
    end

    css_it "wraps the URL in a link tag with & escaped as &amp;" do
      expect(described_class.link("Space Mono", styles: "400,700"))
        .to eq(%(<link rel="stylesheet" href="#{expected_href}">))
    end
  end
end
