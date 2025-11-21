require "spec_helper"
require "fontist/import/google/api"

RSpec.describe Fontist::Import::Google::Api do
  let(:api_key) { Fontist.google_fonts_key }

  before do
    allow(Fontist).to receive(:google_fonts_key).and_return(api_key)
  end

  after(:each) do
    described_class.clear_cache
  end

  describe ".items" do
    it "returns array of FontFamily objects" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            fonts = described_class.items

            expect(fonts).to be_an(Array)
            expect(fonts).not_to be_empty
            expect(fonts.first).to be_a(
              Fontist::Import::Google::Models::FontFamily
            )
          end
        end
      end
    end

    it "returns fonts with complete metadata" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            fonts = described_class.items
            roboto = fonts.find { |f| f.family == "Roboto" }

            expect(roboto).not_to be_nil
            expect(roboto.family).to eq("Roboto")
            expect(roboto.category).not_to be_nil
            expect(roboto.variants).not_to be_empty
            expect(roboto.files).not_to be_empty
          end
        end
      end
    end
  end

  describe ".font_families" do
    it "is an alias for items" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            expect(described_class.font_families).to eq(described_class.items)
          end
        end
      end
    end
  end

  describe ".database" do
    it "returns FontDatabase instance" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            expect(described_class.database).to be_a(
              Fontist::Import::Google::FontDatabase
            )
          end
        end
      end
    end

    it "caches database instance" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            db1 = described_class.database
            db2 = described_class.database

            expect(db1).to be(db2)
          end
        end
      end
    end
  end

  describe ".font_by_name" do
    it "finds font by exact name" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            roboto = described_class.font_by_name("Roboto")

            expect(roboto).not_to be_nil
            expect(roboto.family).to eq("Roboto")
          end
        end
      end
    end

    it "returns nil for non-existent font" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            font = described_class.font_by_name("NonExistentFont12345")

            expect(font).to be_nil
          end
        end
      end
    end
  end

  describe ".by_category" do
    it "filters fonts by category" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            sans_serif = described_class.by_category("sans-serif")

            expect(sans_serif).to be_an(Array)
            expect(sans_serif).not_to be_empty
            sans_serif.each do |font|
              expect(font.category).to eq("sans-serif")
            end
          end
        end
      end
    end

    it "returns empty array for non-existent category" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            fonts = described_class.by_category("non-existent-category")

            expect(fonts).to eq([])
          end
        end
      end
    end
  end

  describe ".variable_fonts_only" do
    it "returns only variable fonts" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            variable = described_class.variable_fonts_only

            expect(variable).to be_an(Array)
            expect(variable).not_to be_empty
            variable.each do |font|
              expect(font.variable_font?).to be true
              expect(font.axes).not_to be_empty
            end
          end
        end
      end
    end
  end

  describe ".static_fonts_only" do
    it "returns only static fonts" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            static = described_class.static_fonts_only

            expect(static).to be_an(Array)
            expect(static).not_to be_empty
            static.each do |font|
              expect(font.variable_font?).to be false
              expect(font.axes).to be_nil
            end
          end
        end
      end
    end
  end

  describe ".fonts_count" do
    it "returns count hash with total, variable, and static" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            counts = described_class.fonts_count

            expect(counts).to be_a(Hash)
            expect(counts).to have_key(:total)
            expect(counts).to have_key(:variable)
            expect(counts).to have_key(:static)

            expect(counts[:total]).to be > 0
            expect(counts[:variable]).to be >= 0
            expect(counts[:static]).to be >= 0
            expect(counts[:total]).to eq(counts[:variable] + counts[:static])
          end
        end
      end
    end
  end

  describe ".ttf_data" do
    it "returns raw TTF endpoint data" do
      stub_google_fonts_api(:ttf) do
        ttf_data = described_class.ttf_data

        expect(ttf_data).to be_an(Array)
        expect(ttf_data).not_to be_empty
        expect(ttf_data.first).to be_a(
          Fontist::Import::Google::Models::FontFamily
        )
      end
    end

    it "returns fonts with TTF file URLs" do
      stub_google_fonts_api(:ttf) do
        ttf_data = described_class.ttf_data
        roboto = ttf_data.find { |f| f.family == "Roboto" }

        expect(roboto).not_to be_nil
        expect(roboto.files).not_to be_empty
        roboto.files.each_value do |url|
          expect(url).to include(".ttf")
        end
      end
    end
  end

  describe ".vf_data" do
    it "returns raw VF endpoint data" do
      stub_google_fonts_api(:vf) do
        vf_data = described_class.vf_data

        expect(vf_data).to be_an(Array)
        expect(vf_data).not_to be_empty
        expect(vf_data.first).to be_a(
          Fontist::Import::Google::Models::FontFamily
        )
      end
    end

    it "includes fonts with axes data" do
      stub_google_fonts_api(:vf) do
        vf_data = described_class.vf_data
        variable = vf_data.select { |f| f.axes && !f.axes.empty? }

        expect(variable).not_to be_empty
        variable.each do |font|
          font.axes.each do |axis|
            expect(axis).to be_a(Fontist::Import::Google::Models::Axis)
            expect(axis.tag).not_to be_nil
          end
        end
      end
    end
  end

  describe ".woff2_data" do
    it "returns raw WOFF2 endpoint data" do
      stub_google_fonts_api(:woff2) do
        woff2_data = described_class.woff2_data

        expect(woff2_data).to be_an(Array)
        expect(woff2_data).not_to be_empty
        expect(woff2_data.first).to be_a(
          Fontist::Import::Google::Models::FontFamily
        )
      end
    end

    it "returns fonts with WOFF2 file URLs" do
      stub_google_fonts_api(:woff2) do
        woff2_data = described_class.woff2_data
        roboto = woff2_data.find { |f| f.family == "Roboto" }

        expect(roboto).not_to be_nil
        expect(roboto.files).not_to be_empty
        roboto.files.each_value do |url|
          expect(url).to include(".woff2")
        end
      end
    end
  end

  describe ".clear_cache" do
    it "clears database cache" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            db1 = described_class.database
            expect(db1).not_to be_nil

            described_class.clear_cache

            db2 = described_class.database
            expect(db2).not_to be(db1)
          end
        end
      end
    end

    it "clears client caches" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            described_class.ttf_data
            described_class.vf_data
            described_class.woff2_data

            expect { described_class.clear_cache }.not_to raise_error
          end
        end
      end
    end
  end

  describe "caching behavior" do
    it "caches database instance across multiple calls" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            db1 = described_class.database
            db2 = described_class.database

            expect(db1).to be(db2)
          end
        end
      end
    end

    it "database delegates to same instance" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            db = described_class.database
            fonts = described_class.items

            expect(fonts).to eq(db.all_fonts)
          end
        end
      end
    end
  end

  describe "data integration" do
    it "merges data from all three endpoints" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            fonts = described_class.items
            variable_font = fonts.find(&:variable_font?)

            expect(variable_font).not_to be_nil
            expect(variable_font.files).not_to be_empty
            expect(variable_font.axes).not_to be_empty
          end
        end
      end
    end

    it "provides consistent data across methods" do
      stub_google_fonts_api(:ttf) do
        stub_google_fonts_api(:vf) do
          stub_google_fonts_api(:woff2) do
            all_fonts = described_class.items
            sans_serif = described_class.by_category("sans-serif")
            variable = described_class.variable_fonts_only

            sans_serif.each do |font|
              expect(all_fonts).to include(font)
            end

            variable.each do |font|
              expect(all_fonts).to include(font)
            end
          end
        end
      end
    end
  end
end