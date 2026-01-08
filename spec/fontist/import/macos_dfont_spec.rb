require "spec_helper"

RSpec.describe "Fontist::Import::Macos dfont support" do
  include_context "fresh home"

  let(:fixture_path) { File.expand_path("../../fixtures/archives", __dir__) }
  let(:charcoal_zip) { File.join(Dir.pwd, "462b6294bf082cbe4119591f3f8b843c0fa6bd35.zip") }
  let(:catalog_path) { File.join(Dir.pwd, "com_apple_MobileAsset_Font3.xml") }
  
  around(:example) { |example| fixtures_dir { example.run } }

  context "when importing dfont files from macOS catalog" do
    it "preserves .dfont extension in formula", :dev do
      skip "Requires catalog and font zip file" unless File.exist?(catalog_path) && File.exist?(charcoal_zip)
      
      # Import Charcoal CY which has a .dfont file
      formula_path = Fontist::Import::CreateFormula.new(
        "http://appldnld.apple.com/ios10.0/031-72027-2016008009-EE8C6F20-5AAD-11E6-B6EF-CCD8464FE3CA/com_apple_MobileAsset_Font3/462b6294bf082cbe4119591f3f8b843c0fa6bd35.zip",
        platforms: ["macos-font3"],
        homepage: "https://support.apple.com/en-om/HT211240#document",
        requires_license_agreement: "Apple",
        formula_dir: ".",
        name: "Charcoal CY",
        import_cache: "/tmp/fontist-test-cache"
      ).call
      
      formula = YAML.load_file(formula_path)
      
      # Verify the formula was created
      expect(formula).not_to be_nil
      expect(formula["name"]).to eq("Charcoal CY")
      
      # Verify fonts section exists
      expect(formula["fonts"]).not_to be_empty
      
      # Find the CharcoalCY font style
      charcoal_font = formula["fonts"].find { |f| f["name"] == "Charcoal CY" }
      expect(charcoal_font).not_to be_nil
      
      # Verify the extension is preserved as .dfont
      regular_style = charcoal_font["styles"].find { |s| s["type"] == "Regular" }
      expect(regular_style).not_to be_nil
      expect(regular_style["font"]).to eq("CharcoalCY.dfont")
      
      # Clean up
      FileUtils.rm_f(formula_path)
    end
  end

  context "when processing .dfont files" do
    it "correctly detects .dfont as a font file", :dev do
      skip "Requires actual dfont file" unless File.exist?(charcoal_zip)
      
      # Extract the zip to get the dfont file
      require "excavate"
      temp_dir = Dir.mktmpdir
      
      begin
        Excavate::Archive.new(charcoal_zip).files do |path|
          if File.basename(path) == "CharcoalCY.dfont"
            # Test FontDetector
            detector_result = Fontist::Import::Files::FontDetector.detect(path)
            expect(detector_result).to eq(:font)
            
            # Test standard_extension
            extension = Fontist::Import::Files::FontDetector.standard_extension(path)
            expect(extension).to eq("dfont")
            
            # Test FontFile
            font_file = Fontist::Import::Otf::FontFile.new(path)
            expect(font_file.font).to end_with(".dfont")
            expect(font_file.family_name).to eq("Charcoal CY")
          end
        end
      ensure
        FileUtils.rm_rf(temp_dir)
      end
    end
  end

  def fixtures_dir
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { yield }
    end
  end
end