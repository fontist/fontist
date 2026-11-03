require "spec_helper"
require "fontist/cli"

RSpec.describe "fontist css" do
  let(:url) do
    "https://fonts.googleapis.com/css2?family=Space+Mono:wght@400;700" \
      "&display=swap"
  end

  css_it "prints only the URL on stdout" do
    status, out, err = run_css("Space Mono", "--styles", "400,700")

    expect([status, out, err]).to eq([0, "#{url}\n", ""])
  end

  css_it "prints the link tag with --format link" do
    status, out, err = run_css("Space Mono", "--styles", "400,700",
                               "--format", "link")

    href = url.gsub("&", "&amp;")
    expect(status).to eq(0)
    expect(out).to eq(%(<link rel="stylesheet" href="#{href}">\n))
    expect(err).to eq("")
  end

  css_it "honours --display" do
    _, out, = run_css("Space Mono", "--display", "block")

    expect(out).to eq(
      "https://fonts.googleapis.com/css2?family=Space+Mono&display=block\n",
    )
  end

  css_it "reports an unknown family on stderr with a nonzero status" do
    status, out, err = run_css("Nonexistent Family")

    expect(status).to eq(Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR)
    expect(out).to eq("")
    expect(err).to include("Nonexistent Family")
  end

  css_it "reports a non-Google family on stderr" do
    status, out, err = run_css("Andale Mono")

    expect(status).not_to eq(0)
    expect(out).to eq("")
    expect(err).to include("not a Google Fonts family")
  end

  css_it "reports an unavailable style on stderr" do
    status, out, err = run_css("Space Mono", "--styles", "300")

    expect(status).not_to eq(0)
    expect(out).to eq("")
    expect(err).to include("Style '300' is not available")
  end

  css_it "reports an invalid --format on stderr" do
    status, out, err = run_css("Space Mono", "--format", "json")

    expect(status).not_to eq(0)
    expect(out).to eq("")
    expect(err).to include("Invalid format 'json'")
  end

  css_it "requires --output-dir with --local" do
    status, out, err = run_css("Space Mono", "--local")

    expect(status).not_to eq(0)
    expect(out).to eq("")
    expect(err).to include("--output-dir")
  end
end
