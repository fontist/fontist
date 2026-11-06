# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fontist::Validator do
  let(:fonts_dir) { Fontist.root_path.join("spec", "fixtures", "fonts") }
  let(:good_font) { fonts_dir.join("DejaVuSerif.ttf").to_s }
  let(:validator) { described_class.new }

  describe "#validate_single" do
    it "reports a valid font with its names and file metadata" do
      result = validator.validate_single(good_font)

      expect(result.valid).to be true
      expect(result.family_name).to eq "DejaVu Serif"
      expect(result.full_name).not_to be_nil
      expect(result.file_size).to eq File.size(good_font)
      expect(result.file_mtime).to eq File.mtime(good_font).to_i
    end

    it "reports a broken font as invalid with an error message" do
      Dir.mktmpdir do |dir|
        broken = File.join(dir, "broken.ttf")
        File.binwrite(broken, "this is not a font")

        result = validator.validate_single(broken)

        expect(result.valid).to be false
        expect(result.error_message).not_to be_empty
        expect(result.file_size).to eq 18
      end
    end
  end

  describe "#validate_all" do
    let(:paths) do
      [good_font, fonts_dir.join("overpass-bold.otf").to_s]
    end

    before do
      allow(validator).to receive(:scan_font_paths).and_return(paths)
    end

    it "validates every scanned font sequentially and in parallel" do
      [false, true].each do |parallel|
        report = described_class.new.tap do |v|
          allow(v).to receive(:scan_font_paths).and_return(paths)
        end.validate_all(parallel: parallel)

        expect(report.results.map(&:path)).to match_array(paths)
        expect(report.results).to all(satisfy(&:valid))
      end
    end

    it "reuses a cache entry when the file is unchanged (hit)" do
      cached = Fontist::FontValidationResult.new(
        path: good_font, valid: true, family_name: "From Cache",
        file_size: File.size(good_font), file_mtime: File.mtime(good_font).to_i
      )
      cache = Fontist::ValidationCache.new(entries: [cached])

      report = validator.validate_all(parallel: false, cache: cache)

      by_path = report.results.to_h { |r| [r.path, r] }
      expect(by_path[good_font].family_name).to eq "From Cache"
      expect(by_path[paths.last].family_name).not_to eq "From Cache"
    end

    it "revalidates when the cached metadata no longer matches (miss)" do
      stale = Fontist::FontValidationResult.new(
        path: good_font, valid: true, family_name: "From Cache",
        file_size: File.size(good_font) + 1,
        file_mtime: File.mtime(good_font).to_i
      )
      cache = Fontist::ValidationCache.new(entries: [stale])

      report = validator.validate_all(parallel: false, cache: cache)

      expect(report.results.to_h { |r| [r.path, r] }[good_font].family_name)
        .to eq "DejaVu Serif"
    end

    it "includes a broken font as invalid without aborting the run" do
      Dir.mktmpdir do |dir|
        broken = File.join(dir, "broken.ttf")
        File.binwrite(broken, "nope")
        allow(validator).to receive(:scan_font_paths)
          .and_return([good_font, broken])

        report = validator.validate_all(parallel: false)

        expect(report.results.map(&:valid)).to eq [true, false]
      end
    end
  end
end
