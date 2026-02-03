require "spec_helper"
require_relative "../../support/macos_catalog_helper"
require_relative "../../../lib/fontist/import/files/font_detector"
require_relative "../../../lib/fontist/import/otf/font_file"

RSpec.describe "Fontist::Import::Macos dfont support" do
  include_context "fresh home"

  let(:fixture_path) { File.expand_path("../../fixtures/fonts", __dir__) }
  let(:dfont_file) { File.join(fixture_path, "Tamsyn7x13.dfont") }
  let(:catalog_path) { MacosCatalogHelper.catalog_path(3) }

  around(:example) { |example| fixtures_dir { example.run } }

  context "when importing dfont files" do
    it "correctly detects .dfont as a collection file", :dev do
      skip "dfont file not available" unless File.exist?(dfont_file)

      # dfont files are collections (can contain multiple fonts)
      detector_result = Fontist::Import::Files::FontDetector.detect(dfont_file)
      expect(detector_result).to eq(:collection)

      # Test standard_extension preserves .dfont extension
      extension = Fontist::Import::Files::FontDetector.standard_extension(dfont_file)
      expect(extension).to eq("dfont")

      # Test FontFile can read the dfont
      font_file = Fontist::Import::Otf::FontFile.new(dfont_file)
      expect(font_file.font).to end_with(".dfont")
      expect(font_file.family_name).to eq("Tamsyn7x13")
    end
  end

  def fixtures_dir(&block)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir, &block)
    end
  end
end
