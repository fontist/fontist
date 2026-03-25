require "spec_helper"
require "fontist/import/v4_to_v5_migrator"
require "tmpdir"
require "yaml"

RSpec.describe Fontist::Import::V4ToV5Migrator do
  let(:tmpdir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(tmpdir) }

  def write_formula(data, filename = "test_font.yml")
    path = File.join(tmpdir, filename)
    File.write(path, YAML.dump(data))
    path
  end

  describe "#migrate_file" do
    it "adds schema_version: 5" do
      formula = {
        "name" => "Test Font",
        "resources" => {
          "TestFont.zip" => {
            "urls" => ["https://example.com/TestFont.zip"],
            "files" => ["TestFont-Regular.ttf"],
          },
        },
        "fonts" => [
          {
            "name" => "Test Font",
            "styles" => [
              {
                "family_name" => "Test Font",
                "type" => "Regular",
                "font" => "TestFont-Regular.ttf",
              },
            ],
          },
        ],
      }

      path = write_formula(formula)
      migrator = described_class.new(path)
      result = migrator.migrate_file(path)

      expect(result).to eq(:migrated)

      migrated = YAML.load_file(path)
      expect(migrated["schema_version"]).to eq(5)
    end

    it "skips already-v5 formulas" do
      formula = {
        "schema_version" => 5,
        "name" => "Already V5",
      }

      path = write_formula(formula)
      migrator = described_class.new(path)
      result = migrator.migrate_file(path)

      expect(result).to eq(:skipped)
    end

    it "detects format from font file extension in resources" do
      formula = {
        "name" => "Font With TTF",
        "resources" => {
          "font_resource" => {
            "urls" => ["https://fonts.example.com/MyFont-Regular.ttf"],
            "files" => ["MyFont-Regular.ttf"],
          },
        },
        "fonts" => [],
      }

      path = write_formula(formula)
      migrator = described_class.new(path)
      migrator.migrate_file(path)

      migrated = YAML.load_file(path)
      expect(migrated["resources"]["font_resource"]["format"]).to eq("ttf")
    end

    it "detects variable axes from filename patterns" do
      formula = {
        "name" => "Variable Font",
        "resources" => {
          "vf_resource" => {
            "urls" => ["https://example.com/Font[wght,ital].ttf"],
            "files" => ["Font[wght,ital].ttf"],
          },
        },
        "fonts" => [],
      }

      path = write_formula(formula)
      migrator = described_class.new(path)
      migrator.migrate_file(path)

      migrated = YAML.load_file(path)
      resource = migrated["resources"]["vf_resource"]
      expect(resource["variable_axes"]).to eq(%w[wght ital])
    end

  end

  describe "#migrate_all" do
    it "returns migration summary" do
      write_formula({ "name" => "Font A", "resources" => {}, "fonts" => [] }, "a.yml")
      write_formula({ "schema_version" => 5, "name" => "Font B" }, "b.yml")

      migrator = described_class.new(tmpdir)
      results = migrator.migrate_all

      expect(results[:migrated]).to eq(1)
      expect(results[:skipped]).to eq(1)
      expect(results[:failed]).to eq(0)
    end

    it "handles dry_run mode without writing" do
      formula = { "name" => "Dry Run Font", "resources" => {}, "fonts" => [] }
      path = write_formula(formula)
      original_content = File.read(path)

      migrator = described_class.new(tmpdir, nil, dry_run: true)
      results = migrator.migrate_all

      expect(results[:migrated]).to eq(1)
      expect(File.read(path)).to eq(original_content)
    end
  end
end
