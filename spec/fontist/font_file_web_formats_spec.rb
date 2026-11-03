require "spec_helper"
require "tmpdir"

RSpec.describe Fontist::FontFile, ".from_path" do
  let(:ttf) { File.expand_path("../examples/fonts/Lato-Heavy.ttf", __dir__) }

  %w[woff woff2].each do |format|
    it "reads the names of a #{format} font" do
      Dir.mktmpdir do |dir|
        path = Fontist::FontOperations::Convert.call(
          ttf, format, File.join(dir, "lato.#{format}")
        )

        expect(described_class.from_path(path).full_name)
          .to eq(described_class.from_path(ttf).full_name)
      end
    end
  end
end
