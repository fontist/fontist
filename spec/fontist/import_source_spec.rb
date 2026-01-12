require "spec_helper"
require_relative "../../lib/fontist/import_source"
require_relative "../../lib/fontist/macos_import_source"
require_relative "../../lib/fontist/google_import_source"
require_relative "../../lib/fontist/sil_import_source"

RSpec.describe Fontist::ImportSource do
  describe "abstract methods" do
    it "raises NotImplementedError for differentiation_key on base class" do
      source = described_class.new

      expect {
        source.differentiation_key
      }.to raise_error(NotImplementedError, /must implement #differentiation_key/)
    end

    it "raises NotImplementedError for outdated? on base class" do
      source = described_class.new

      expect {
        source.outdated?(double)
      }.to raise_error(NotImplementedError, /must implement #outdated\?/)
    end
  end
end