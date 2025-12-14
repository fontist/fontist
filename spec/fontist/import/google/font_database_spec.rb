require "spec_helper"
require "fontist/import/google/font_database"
require "fontist/import/google/models/font_family"
require "fontist/import/google/models/axis"

RSpec.describe Fontist::Import::Google::FontDatabase do
  let(:ttf_font1) do
    Fontist::Import::Google::Models::FontFamily.new(
      family: "ABeeZee",
      variants: ["regular", "italic"],
      subsets: ["latin"],
      version: "v23",
      last_modified: "2025-09-08",
      files: {
        "regular" => "https://fonts.gstatic.com/s/abeezee/v23/regular.ttf",
        "italic" => "https://fonts.gstatic.com/s/abeezee/v23/italic.ttf",
      },
      category: "sans-serif",
      kind: "webfonts#webfont",
      menu: "https://fonts.gstatic.com/s/abeezee/v23/menu.ttf",
    )
  end

  let(:ttf_font2) do
    Fontist::Import::Google::Models::FontFamily.new(
      family: "Roboto",
      variants: ["regular", "bold"],
      subsets: ["latin"],
      version: "v30",
      last_modified: "2025-08-15",
      files: {
        "regular" => "https://fonts.gstatic.com/s/roboto/v30/regular.ttf",
        "bold" => "https://fonts.gstatic.com/s/roboto/v30/bold.ttf",
      },
      category: "sans-serif",
      kind: "webfonts#webfont",
    )
  end

  let(:vf_font1) do
    Fontist::Import::Google::Models::FontFamily.new(
      family: "AR One Sans",
      variants: ["regular"],
      subsets: ["latin"],
      version: "v6",
      last_modified: "2025-07-20",
      files: {
        "regular" => "https://fonts.gstatic.com/s/aronesans/v6/regular.ttf",
      },
      category: "sans-serif",
      kind: "webfonts#webfont",
      axes: [
        Fontist::Import::Google::Models::Axis.new(
          tag: "ARRR",
          start: 10,
          end: 60,
        ),
        Fontist::Import::Google::Models::Axis.new(
          tag: "wght",
          start: 400,
          end: 700,
        ),
      ],
    )
  end

  let(:vf_font2) do
    Fontist::Import::Google::Models::FontFamily.new(
      family: "ABeeZee",
      variants: ["regular", "italic"],
      subsets: ["latin"],
      version: "v23",
      last_modified: "2025-09-08",
      files: {
        "regular" => "https://fonts.gstatic.com/s/abeezee/v23/regular.ttf",
        "italic" => "https://fonts.gstatic.com/s/abeezee/v23/italic.ttf",
      },
      category: "sans-serif",
      kind: "webfonts#webfont",
    )
  end

  let(:woff2_font1) do
    Fontist::Import::Google::Models::FontFamily.new(
      family: "ABeeZee",
      variants: ["regular", "italic"],
      subsets: ["latin"],
      version: "v23",
      last_modified: "2025-09-08",
      files: {
        "regular" => "https://fonts.gstatic.com/s/abeezee/v23/regular.woff2",
        "italic" => "https://fonts.gstatic.com/s/abeezee/v23/italic.woff2",
      },
      category: "sans-serif",
      kind: "webfonts#webfont",
    )
  end

  let(:woff2_font2) do
    Fontist::Import::Google::Models::FontFamily.new(
      family: "Roboto",
      variants: ["regular", "bold"],
      subsets: ["latin"],
      version: "v30",
      last_modified: "2025-08-15",
      files: {
        "regular" => "https://fonts.gstatic.com/s/roboto/v30/regular.woff2",
        "bold" => "https://fonts.gstatic.com/s/roboto/v30/bold.woff2",
      },
      category: "sans-serif",
      kind: "webfonts#webfont",
    )
  end

  let(:ttf_data) { [ttf_font1, ttf_font2] }
  let(:vf_data) { [vf_font1, vf_font2] }
  let(:woff2_data) { [woff2_font1, woff2_font2] }

  describe "#initialize" do
    it "accepts data from three endpoints" do
      db = described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
      )
      expect(db).to be_a(described_class)
    end

    it "handles empty arrays" do
      db = described_class.new(
        ttf_data: [],
        vf_data: [],
        woff2_data: [],
      )
      expect(db.all_fonts).to be_empty
    end

    it "handles nil values by converting to arrays" do
      db = described_class.new(
        ttf_data: nil,
        vf_data: nil,
        woff2_data: nil,
      )
      expect(db.all_fonts).to be_empty
    end

    it "merges data during initialization" do
      db = described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
      )
      expect(db.fonts).to be_a(Hash)
      expect(db.fonts).not_to be_empty
    end
  end

  describe "#all_fonts" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5 to include variable fonts
      )
    end

    it "returns array of all font families" do
      fonts = db.all_fonts
      expect(fonts).to be_an(Array)
      expect(fonts).not_to be_empty
    end

    it "returns merged font families" do
      fonts = db.all_fonts
      expect(fonts.map(&:family)).to include("ABeeZee", "Roboto",
                                             "AR One Sans")
    end

    it "returns unique families" do
      fonts = db.all_fonts
      family_names = fonts.map(&:family)
      expect(family_names.uniq.count).to eq(family_names.count)
    end
  end

  describe "#font_by_name" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    it "finds font by exact family name" do
      font = db.font_by_name("ABeeZee")
      expect(font).not_to be_nil
      expect(font.family).to eq("ABeeZee")
    end

    it "returns nil for non-existent family" do
      font = db.font_by_name("NonExistent")
      expect(font).to be_nil
    end

    it "is case-sensitive" do
      font = db.font_by_name("abeezee")
      expect(font).to be_nil
    end
  end

  describe "#by_category" do
    let(:serif_font) do
      Fontist::Import::Google::Models::FontFamily.new(
        family: "Merriweather",
        variants: ["regular"],
        subsets: ["latin"],
        version: "v30",
        last_modified: "2025-08-15",
        files: { "regular" => "https://example.com/font.ttf" },
        category: "serif",
        kind: "webfonts#webfont",
      )
    end

    let(:db) do
      described_class.new(
        ttf_data: ttf_data + [serif_font],
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    it "filters fonts by category" do
      sans_fonts = db.by_category("sans-serif")
      expect(sans_fonts).to all(have_attributes(category: "sans-serif"))
    end

    it "returns empty array for non-existent category" do
      fonts = db.by_category("monospace")
      expect(fonts).to be_empty
    end

    it "finds serif fonts" do
      serif_fonts = db.by_category("serif")
      expect(serif_fonts.count).to eq(1)
      expect(serif_fonts.first.family).to eq("Merriweather")
    end
  end

  describe "#variable_fonts_only" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5 to include VFs
      )
    end

    it "returns only fonts with axes" do
      vf_fonts = db.variable_fonts_only
      expect(vf_fonts).to all(be_variable_font)
    end

    it "includes AR One Sans" do
      vf_fonts = db.variable_fonts_only
      expect(vf_fonts.map(&:family)).to include("AR One Sans")
    end

    it "excludes fonts without axes" do
      vf_fonts = db.variable_fonts_only
      expect(vf_fonts.map(&:family)).not_to include("Roboto")
    end
  end

  describe "#static_fonts_only" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    it "returns only fonts without axes" do
      static_fonts = db.static_fonts_only
      expect(static_fonts).to all(satisfy { |f| !f.variable_font? })
    end

    it "includes ABeeZee and Roboto" do
      static_fonts = db.static_fonts_only
      expect(static_fonts.map(&:family)).to include("ABeeZee", "Roboto")
    end

    it "excludes variable fonts" do
      static_fonts = db.static_fonts_only
      expect(static_fonts.map(&:family)).not_to include("AR One Sans")
    end
  end

  describe "#fonts_count" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    it "returns hash with counts" do
      counts = db.fonts_count
      expect(counts).to be_a(Hash)
      expect(counts).to have_key(:total)
      expect(counts).to have_key(:variable)
      expect(counts).to have_key(:static)
    end

    it "counts total fonts correctly" do
      counts = db.fonts_count
      expect(counts[:total]).to eq(3)
    end

    it "counts variable fonts correctly" do
      counts = db.fonts_count
      expect(counts[:variable]).to eq(1)
    end

    it "counts static fonts correctly" do
      counts = db.fonts_count
      expect(counts[:static]).to eq(2)
    end

    it "total equals variable plus static" do
      counts = db.fonts_count
      expect(counts[:total]).to eq(counts[:variable] + counts[:static])
    end
  end

  describe "#categories" do
    let(:serif_font) do
      Fontist::Import::Google::Models::FontFamily.new(
        family: "Merriweather",
        variants: ["regular"],
        subsets: ["latin"],
        version: "v30",
        last_modified: "2025-08-15",
        files: { "regular" => "https://example.com/font.ttf" },
        category: "serif",
        kind: "webfonts#webfont",
      )
    end

    let(:db) do
      described_class.new(
        ttf_data: ttf_data + [serif_font],
        vf_data: vf_data,
        woff2_data: woff2_data,
      )
    end

    it "returns array of unique categories" do
      categories = db.categories
      expect(categories).to be_an(Array)
      expect(categories.uniq).to eq(categories)
    end

    it "includes all present categories" do
      categories = db.categories
      expect(categories).to include("sans-serif", "serif")
    end

    it "returns sorted categories" do
      categories = db.categories
      expect(categories).to eq(categories.sort)
    end
  end

  describe "file merging" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    it "stores TTF and WOFF2 files separately" do
      expect(db.ttf_files).to be_a(Hash)
      expect(db.woff2_files).to be_a(Hash)
    end

    it "stores TTF files for ABeeZee" do
      ttf_files = db.ttf_files_for("ABeeZee")
      expect(ttf_files).not_to be_nil
      expect(ttf_files["regular"]).to include(".ttf")
    end

    it "stores WOFF2 files for ABeeZee" do
      woff2_files = db.woff2_files_for("ABeeZee")
      expect(woff2_files).not_to be_nil
      expect(woff2_files["regular"]).to include(".woff2")
    end

    it "uses TTF files in merged font family" do
      abeezee = db.font_by_name("ABeeZee")
      expect(abeezee.files["regular"]).to include(".ttf")
    end

    it "handles variants from TTF endpoint" do
      roboto = db.font_by_name("Roboto")
      expect(roboto.files).to have_key("regular")
      expect(roboto.files).to have_key("bold")
    end
  end

  describe "axes merging" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5 for variable fonts
      )
    end

    it "adds axes from VF endpoint" do
      ar_one_sans = db.font_by_name("AR One Sans")
      expect(ar_one_sans.axes).not_to be_nil
      expect(ar_one_sans.axes).not_to be_empty
    end

    it "preserves axis data" do
      ar_one_sans = db.font_by_name("AR One Sans")
      expect(ar_one_sans.axes.count).to eq(2)
      expect(ar_one_sans.axes.map(&:tag)).to include("ARRR", "wght")
    end

    it "does not add axes to static fonts" do
      abeezee = db.font_by_name("ABeeZee")
      expect(abeezee.axes).to be_nil
    end
  end

  describe "version and date merging" do
    let(:newer_ttf_font) do
      Fontist::Import::Google::Models::FontFamily.new(
        family: "TestFont",
        variants: ["regular"],
        subsets: ["latin"],
        version: "v25",
        last_modified: "2025-09-15",
        files: { "regular" => "https://example.com/v25.ttf" },
        category: "sans-serif",
        kind: "webfonts#webfont",
      )
    end

    let(:older_woff2_font) do
      Fontist::Import::Google::Models::FontFamily.new(
        family: "TestFont",
        variants: ["regular"],
        subsets: ["latin"],
        version: "v20",
        last_modified: "2025-08-01",
        files: { "regular" => "https://example.com/v20.woff2" },
        category: "sans-serif",
        kind: "webfonts#webfont",
      )
    end

    let(:db) do
      described_class.new(
        ttf_data: [newer_ttf_font],
        vf_data: [],
        woff2_data: [older_woff2_font],
      )
    end

    it "uses most recent version" do
      font = db.font_by_name("TestFont")
      expect(font.version).to eq("v25")
    end

    it "uses most recent date" do
      font = db.font_by_name("TestFont")
      expect(font.last_modified).to eq("2025-09-15")
    end
  end

  describe "edge cases" do
    it "handles font only in TTF endpoint" do
      db = described_class.new(
        ttf_data: [ttf_font1],
        vf_data: [],
        woff2_data: [],
      )

      font = db.font_by_name("ABeeZee")
      expect(font).not_to be_nil
      expect(db.ttf_files_for("ABeeZee")).not_to be_nil
      expect(db.woff2_files_for("ABeeZee")).to be_nil
    end

    it "handles font only in WOFF2 endpoint" do
      db = described_class.new(
        ttf_data: [],
        vf_data: [],
        woff2_data: [woff2_font1],
      )

      font = db.font_by_name("ABeeZee")
      expect(font).not_to be_nil
      expect(db.woff2_files_for("ABeeZee")).not_to be_nil
      expect(db.ttf_files_for("ABeeZee")).to be_nil
    end

    it "handles font only in VF endpoint" do
      db = described_class.new(
        ttf_data: [],
        vf_data: [vf_font1],
        woff2_data: [],
        version: 5,  # Must use v5 for VF fonts
      )

      font = db.font_by_name("AR One Sans")
      expect(font).not_to be_nil
      expect(font.variable_font?).to be true
    end

    it "handles missing metadata fields gracefully" do
      incomplete_font = Fontist::Import::Google::Models::FontFamily.new(
        family: "Incomplete",
        variants: ["regular"],
        files: { "regular" => "https://example.com/font.ttf" },
      )

      db = described_class.new(
        ttf_data: [incomplete_font],
        vf_data: [],
        woff2_data: [],
      )

      font = db.font_by_name("Incomplete")
      expect(font).not_to be_nil
      expect(font.family).to eq("Incomplete")
    end
  end

  describe "#fonts_with_ttf" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    it "returns fonts with TTF files" do
      fonts = db.fonts_with_ttf
      expect(fonts).not_to be_empty
      expect(fonts.map(&:family)).to include("ABeeZee", "Roboto")
    end
  end

  describe "#fonts_with_woff2" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    it "returns fonts with WOFF2 files" do
      fonts = db.fonts_with_woff2
      expect(fonts).not_to be_empty
      expect(fonts.map(&:family)).to include("ABeeZee", "Roboto")
    end
  end

  describe "#fonts_with_both_formats" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    it "returns fonts with both TTF and WOFF2" do
      fonts = db.fonts_with_both_formats
      expect(fonts).not_to be_empty
      expect(fonts.map(&:family)).to include("ABeeZee", "Roboto")
    end

    it "excludes fonts with only one format" do
      db_partial = described_class.new(
        ttf_data: [ttf_font1],
        vf_data: [],
        woff2_data: [],
      )

      fonts = db_partial.fonts_with_both_formats
      expect(fonts).to be_empty
    end
  end

  describe ".build" do
    it "accepts api_key parameter" do
      # Stub the data sources to return real fixture objects
      ttf_client = Fontist::Import::Google::DataSources::Ttf.new(api_key: "test_key")
      allow(Fontist::Import::Google::DataSources::Ttf).to receive(:new).and_return(ttf_client)
      allow(ttf_client).to receive(:fetch).and_return([ttf_font1, ttf_font2])

      db = described_class.build(api_key: "test_key")
      expect(db).to be_a(described_class)
    end

    it "accepts optional source_path" do
      # Stub the data sources with real fixture objects
      ttf_client = Fontist::Import::Google::DataSources::Ttf.new(api_key: "test_key")
      allow(Fontist::Import::Google::DataSources::Ttf).to receive(:new).and_return(ttf_client)
      allow(ttf_client).to receive(:fetch).and_return([ttf_font1, ttf_font2])

      db = described_class.build(
        api_key: "test_key",
        source_path: nil,
      )
      expect(db).to be_a(described_class)
    end
  end

  describe "#to_formula" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    it "generates formula for existing family" do
      formula = db.to_formula("ABeeZee")
      expect(formula).to be_a(Hash)
    end

    it "returns nil for non-existent family" do
      formula = db.to_formula("NonExistent")
      expect(formula).to be_nil
    end

    it "includes required formula fields" do
      formula = db.to_formula("ABeeZee")
      expect(formula).to have_key(:name)
      expect(formula).to have_key(:description)
      expect(formula).to have_key(:homepage)
      expect(formula).to have_key(:resources)
      expect(formula).to have_key(:fonts)
    end

    it "generates formula name from family name" do
      formula = db.to_formula("ABeeZee")
      expect(formula[:name]).to eq("abeezee")
    end

    it "includes license information" do
      formula = db.to_formula("ABeeZee")
      expect(formula).to have_key(:license)
      expect(formula).to have_key(:license_url)
      expect(formula).to have_key(:open_license)
    end
  end

  describe "#to_formulas" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    it "generates formulas for all families" do
      formulas = db.to_formulas
      expect(formulas).to be_an(Array)
      expect(formulas.count).to eq(3)
    end

    it "returns valid formula hashes" do
      formulas = db.to_formulas
      formulas.each do |formula|
        expect(formula).to be_a(Hash)
        expect(formula).to have_key(:name)
      end
    end
  end

  describe "#save_formulas" do
    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        version: 5,  # Use v5
      )
    end

    let(:temp_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it "saves all formulas to directory" do
      paths = db.save_formulas(temp_dir)
      expect(paths).to be_an(Array)
      expect(paths).not_to be_empty
    end

    it "creates YAML files" do
      paths = db.save_formulas(temp_dir)
      paths.each do |path|
        expect(File.exist?(path)).to be true
        expect(path).to end_with(".yml")
      end
    end

    it "saves specific family when specified" do
      paths = db.save_formulas(temp_dir, family_name: "ABeeZee")
      expect(paths.count).to eq(1)
      expect(paths.first).to include("abeezee")
    end

    it "creates valid YAML files" do
      paths = db.save_formulas(temp_dir)
      paths.each do |path|
        content = YAML.load_file(path)
        expect(content).to be_a(Hash)
      end
    end
  end

  describe "with GitHub data" do
    let(:github_font) do
      Fontist::Import::Google::Models::FontFamily.new(
        family: "ABeeZee",
        designer: "Anja Meiners",
        license: "OFL-1.1",
        license_text: "Copyright 2011 by Anja Meiners...",
        description: "ABeeZee is a children's learning font.",
        homepage: "http://abeezee.fontlibrary.org",
      )
    end

    let(:db) do
      described_class.new(
        ttf_data: ttf_data,
        vf_data: vf_data,
        woff2_data: woff2_data,
        github_data: [github_font],
        version: 5,  # Use v5
      )
    end

    it "merges GitHub metadata" do
      font = db.font_by_name("ABeeZee")
      expect(font.designer).to eq("Anja Meiners")
      expect(font.license).to eq("OFL-1.1")
      expect(font.description).to eq("ABeeZee is a children's learning font.")
    end

    it "includes GitHub data in formula" do
      formula = db.to_formula("ABeeZee")
      expect(formula[:description]).to eq(
        "ABeeZee is a children's learning font.",
      )
      expect(formula[:copyright]).to eq("Copyright 2011 by Anja Meiners...")
    end

    it "exposes github_data" do
      expect(db.github_data).to be_a(Hash)
      expect(db.github_data["ABeeZee"]).to eq(github_font)
    end
  end
end
