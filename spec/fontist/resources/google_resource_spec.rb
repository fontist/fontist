require "spec_helper"
require_relative "../../../lib/fontist/resources/google_resource"

RSpec.describe Fontist::Resources::GoogleResource do
  describe "#font_urls (private)" do
    subject(:google_resource) { described_class.new(resource) }

    context "with legacy full-URL files (files == urls)" do
      let(:resource) do
        double(
          "Resource",
          files: [
            "https://fonts.gstatic.com/s/roboto/v30/Roboto-Regular.ttf",
            "https://fonts.gstatic.com/s/roboto/v30/Roboto-Bold.ttf",
          ],
          urls: [
            "https://fonts.gstatic.com/s/roboto/v30/Roboto-Regular.ttf",
            "https://fonts.gstatic.com/s/roboto/v30/Roboto-Bold.ttf",
          ],
        )
      end

      it "uses files directly as URLs (legacy behavior)" do
        urls = google_resource.send(:font_urls, ["Roboto-Regular.ttf"])
        expect(urls).to eq(["https://fonts.gstatic.com/s/roboto/v30/Roboto-Regular.ttf"])
      end
    end

    context "with no urls field (legacy v4)" do
      let(:resource) do
        double(
          "Resource",
          files: [
            "https://fonts.gstatic.com/s/roboto/v30/Roboto-Regular.ttf",
          ],
          urls: [],
        )
      end

      it "falls back to legacy behavior" do
        urls = google_resource.send(:font_urls, ["Roboto-Regular.ttf"])
        expect(urls).to eq(["https://fonts.gstatic.com/s/roboto/v30/Roboto-Regular.ttf"])
      end
    end
  end
end
