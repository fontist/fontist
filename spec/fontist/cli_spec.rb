require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::CLI do
  describe "#install" do
    context "supported font name" do
      it "returns success status" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          status = described_class.start(["install", "overpass"])
          expect(status).to be 0
        end
      end
    end

    context "unexisting font name" do
      it "returns error status" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          status = described_class.start(["install", "unexisting"])
          expect(status).to be 1
        end
      end
    end
  end
end
