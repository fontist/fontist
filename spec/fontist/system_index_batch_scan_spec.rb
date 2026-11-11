require "spec_helper"
require "tmpdir"

RSpec.describe "Batch font scan for the indexes" do
  let(:fonts) { Fontist.root_path.join("spec", "fixtures", "fonts") }
  let(:examples) { Fontist.root_path.join("spec", "examples", "fonts") }

  def collection
    Fontist::SystemIndexFontCollection.new
  end

  def capture_ui
    lines = []
    %i[warn error debug say].each do |level|
      allow(Fontist.ui).to receive(level) { |msg| lines << [level, msg.to_s] }
    end
    yield
    lines.sort
  end

  describe Fontist::SystemIndexFontCollection do
    let(:dir) { Dir.mktmpdir }
    let(:paths) do
      FileUtils.cp(fonts.join("DejaVuSerif.ttf"), dir)
      FileUtils.cp(fonts.join("overpass-bold.otf"), dir)
      FileUtils.cp(fonts.join("MonaSansVF", "MonaSansMonoVF[wght].ttf"), dir)
      FileUtils.cp(fonts.join("corrupt", "Rupali_0.72.ttf"), dir)
      FileUtils.cp(examples.join("NotoSansOriya.ttc"), dir)
      # a collection with a misleading extension, a single font renamed, junk
      FileUtils.cp(examples.join("Times.ttc"), File.join(dir, "times.ttf"))
      FileUtils.cp(fonts.join("DejaVuSerif.ttf"), File.join(dir, "dejavu.dat"))
      File.binwrite(File.join(dir, "broken.ttf"), "this is not a font")
      Dir.children(dir).sort.map { |f| File.join(dir, f) }
    end

    after { FileUtils.remove_entry(dir) }

    it "indexes a fixture directory exactly as the per-file path does" do
      old = nil
      old_lines = capture_ui do
        old = paths.flat_map { |p| Array(collection.send(:detect_fonts, p)) }
      end
      new = nil
      new_lines = capture_ui do
        new = collection.send(:detect_paths, paths)
      end

      expect(new.map(&:to_yaml).sort).to eq old.compact.map(&:to_yaml).sort
      expect(new).not_to be_empty
      expect(new_lines).to eq old_lines
      expect(new_lines).not_to be_empty
    end

    it "scans every cache miss in one Fontisan.scan call" do
      allow(Fontisan).to receive(:scan).and_call_original

      collection.send(:detect_paths, paths)

      expect(Fontisan).to have_received(:scan).once
      expect(Fontisan).to have_received(:scan).with(paths.sort)
    end

    it "maps clean rows without the per-file loader" do
      col = collection
      allow(col).to receive(:detect_fonts).and_call_original

      col.send(:detect_paths, paths)

      fallbacks = []
      expect(col).to have_received(:detect_fonts).at_least(:once) do |path, **|
        fallbacks << File.basename(path)
      end
      expect(fallbacks.sort).to eq ["broken.ttf"]
    end

    it "does not scan files whose cached entry is unchanged" do
      first = collection.send(:detect_paths, paths)
      cached = collection.tap { |c| c.fonts = first }
      allow(Fontisan).to receive(:scan).and_call_original

      cached.send(:detect_paths, paths)

      expect(Fontisan).not_to have_received(:scan)
        .with(array_including(*first.map(&:path).uniq))
    end
  end

  describe "SystemFont reset hook" do
    it "reuses the scanned paths until reset, then re-reads the fonts" do
      Fontist::SystemFont.reset_font_paths_cache
      Fontist::SystemIndex.reset_cache
      FileUtils.mkdir_p(Fontist.fonts_path)
      first = Fontist.fonts_path.join("DejaVuSerif.ttf")
      second = Fontist.fonts_path.join("overpass-bold.otf")
      FileUtils.cp(fonts.join("DejaVuSerif.ttf"), first)
      scanned = []
      allow(Fontisan).to receive(:scan).and_wrap_original do |m, paths|
        scanned << paths.map(&:to_s)
        m.call(paths)
      end

      index = Fontist::SystemIndex.fontist_index
      index.rebuild
      expect(scanned.flatten).to eq [first.to_s]

      FileUtils.cp(fonts.join("overpass-bold.otf"), second)
      scanned.clear
      index.rebuild
      expect(scanned.flatten).not_to include(second.to_s)

      Fontist::SystemFont.reset_font_paths_cache
      Fontist::SystemIndex.reset_cache
      Fontist::SystemIndex.fontist_index.rebuild
      expect(scanned.flatten).to include(second.to_s)
    ensure
      FileUtils.rm_f([first, second].compact)
      Fontist::SystemFont.reset_font_paths_cache
      Fontist::SystemIndex.reset_cache
    end
  end

  describe "batch scan code paths" do
    touched = %w[system_index.rb validator.rb scan_row_fonts.rb font_file.rb
                 collection_file.rb].map do |f|
      File.join(Fontist.root_path, "lib", "fontist", f)
    end

    it "uses no Marshal, no fork, and no uncapped Parallel" do
      touched.each do |file|
        code = File.readlines(file).reject { |l| l.strip.start_with?("#") }
        source = code.join
        expect(source).not_to match(/\bMarshal\b/), file
        expect(source).not_to match(/\b(Process\.)?fork\b/), file
        source.scan(/Parallel\.\w+\([^)]*\)/).each do |call|
          expect(call).to match(/in_threads:\s*num_cores/), "#{file}: #{call}"
        end
        expect(source).not_to match(/in_processes/), file
      end
    end
  end
end
