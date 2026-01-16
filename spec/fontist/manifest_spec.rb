require "spec_helper"

RSpec.describe Fontist::Manifest do
  describe "parsing" do
    let(:manifest_path) { "spec/examples/manifests/mscorefonts.yml" }
    it "round-trips" do
      content = "---\n#{File.read(manifest_path).split("---\n").last}"
      manifest = described_class.from_yaml(content)
      expect(manifest.to_yaml).to eq(content)
    end
  end

  describe ".from_yaml" do
    let(:instance) { described_class.from_yaml(manifest) }

    context "empty manifest" do
      let(:manifest) { {}.to_yaml }

      it "returns empty result" do
        no_fonts do
          expect(instance).to be_empty
        end
      end
    end

    context "manifest given" do
      let(:manifest) { { "Andale Mono" => ["Regular"] }.to_yaml }

      it "deserialize correctly" do
        no_fonts do
          example_font_to_fontist("AndaleMo.TTF")
          expect(instance.first.name).to eq("Andale Mono")
          expect(instance.first.styles).to eq(["Regular"])
        end
      end
    end
  end

  describe "install" do
    describe ".from_hash" do
      include_context "fresh home"
      before { example_formula("andale.yml") }

      let(:instance) { described_class.from_hash(manifest).install }
      let(:manifest) { { "Andale Mono" => "Regular" } }

      context "confirmation option passed" do
        let(:instance) do
          described_class.from_hash(manifest).install(confirmation: "yes")
        end

        it "accepts it with no error" do
          expect { instance }.not_to raise_error
        end
      end

      context "unsupported font" do
        let(:manifest) { { "Non-existing Font" => ["Regular"] } }

        it "raises non-supported font error" do
          expect { instance }.to raise_error Fontist::Errors::UnsupportedFontError
          expect { instance }.to(
            raise_error { |e| expect(e.font).to eq "Non-existing Font" },
          )
        end
      end

      context "requires license confirmation and no flag passed" do
        before { stub_license_agreement_prompt_with("no") }

        it "raises licensing error" do
          expect { instance }.to raise_error Fontist::Errors::LicensingError
        end
      end

      context "confirmation option passed as no and nil input is returned" do
        let(:instance) do
          described_class.from_hash(manifest).install(confirmation: "no")
        end
        before { stub_license_agreement_prompt_with(nil) }

        it "raises licensing error" do
          expect { instance }.to raise_error Fontist::Errors::LicensingError
        end
      end

      context "no_progress option passed" do
        it "accepts it with no error" do
          expect do
            described_class.from_hash(manifest,
                                      no_progress: true,
                                      confirmation: "yes")
          end.not_to raise_error
        end
      end

      context "preferred family and no option" do
        let(:manifest) { { "TeXGyreChorus" => nil } }
        before { example_formula("tex_gyre_chorus.yml") }

        it "installs by default family" do
          expect { instance }.not_to raise_error
        end
      end

      context "with location parameter" do
        let(:manifest) { { "Andale Mono" => "Regular" } }
        before { example_formula("andale.yml") }

        context "valid locations" do
          it "installs all fonts to user location" do
            # Mock file copy to avoid writing to actual user directory
            # Note: We don't mock mkdir_p because it's needed for lock file creation
            allow(FileUtils).to receive(:cp).and_return(true)

            expect do
              described_class.from_hash(manifest)
                .install(confirmation: "yes", location: :user)
            end.not_to raise_error
          end

          it "installs all fonts to system location" do
            # Mock file operations to avoid permission errors
            # Note: We don't mock mkdir_p because it's needed for lock file creation
            allow(Fontist.ui).to receive(:say) # Suppress warnings
            allow(FileUtils).to receive(:cp).and_return(true)

            expect do
              described_class.from_hash(manifest)
                .install(confirmation: "yes", location: :system)
            end.not_to raise_error
          end

          it "installs all fonts to fontist location" do
            expect do
              described_class.from_hash(manifest)
                .install(confirmation: "yes", location: :fontist)
            end.not_to raise_error
          end
        end

        context "invalid locations" do
          it "shows error for invalid location but proceeds" do
            expect(Fontist.ui).to receive(:error).with(include("Invalid install location"))
            result = described_class.from_hash(manifest)
              .install(confirmation: "yes", location: :invalid)
            expect(result).to be_a(Fontist::ManifestResponse)
          end

          it "raises ArgumentError for string location parameter" do
            expect do
              described_class.from_hash(manifest)
                .install(confirmation: "yes", location: "user")
            end.to raise_error(ArgumentError, /location must be a Symbol/)
          end

          it "raises ArgumentError for custom path (string)" do
            expect do
              described_class.from_hash(manifest)
                .install(confirmation: "yes", location: "/custom/path")
            end.to raise_error(ArgumentError, /location must be a Symbol/)
          end
        end

        context "location applied to all fonts" do
          let(:manifest) do
            { "Andale Mono" => "Regular",
              "Courier New" => "Bold" }
          end
          before { example_formula("courier.yml") }

          it "passes location to each font installation" do
            expect(Fontist::Font).to receive(:install)
              .with("Andale Mono", hash_including(location: :user))
              .and_call_original
            expect(Fontist::Font).to receive(:install)
              .with("Courier New", hash_including(location: :user))
              .and_call_original

            described_class.from_hash(manifest)
              .install(confirmation: "yes", location: :user)
          end
        end
      end
    end
  end

  describe "performance optimizations" do
    include_context "fresh home"
    before { example_formula("andale.yml") }

    describe ".with_performance_optimizations" do
      it "enables read-only mode on all indexes" do
        expect(Fontist::Indexes::FontistIndex.instance).to receive(:read_only_mode).and_call_original
        expect(Fontist::Indexes::UserIndex.instance).to receive(:read_only_mode).and_call_original
        expect(Fontist::Indexes::SystemIndex.instance).to receive(:read_only_mode).and_call_original

        described_class.with_performance_optimizations do
          # Just verify the mode was enabled
        end
      end

      it "enables caching for find_styles lookups" do
        expect(Fontist::SystemFont).to receive(:enable_find_styles_cache).and_call_original
        expect(Fontist::SystemFont).to receive(:disable_find_styles_cache).at_least(:once).and_call_original

        described_class.with_performance_optimizations do
          # Just verify caching was enabled
        end
      end

      it "disables caching after execution even if error occurs" do
        # Enable caching before the test
        Fontist::SystemFont.enable_find_styles_cache
        expect(Fontist::SystemFont).to receive(:disable_find_styles_cache).at_least(:once).and_call_original

        begin
          described_class.with_performance_optimizations do
            raise "Test error"
          end
        rescue RuntimeError => e
          expect(e.message).to eq("Test error")
        end

        # Verify caching was disabled despite the error
        expect(Fontist::SystemFont.instance_variable_get(:@find_styles_cache_enabled)).to be false
      end
    end

    describe "manifest compilation with optimizations" do
      it "uses performance optimizations during from_file" do
        manifest_path = File.join("spec", "examples", "manifests",
                                  "mscorefonts.yml")

        expect(described_class).to receive(:with_performance_optimizations).and_call_original

        described_class.from_file(manifest_path)
      end

      it "uses performance optimizations during from_hash" do
        manifest = { "Andale Mono" => "Regular" }

        expect(described_class).to receive(:with_performance_optimizations).and_call_original

        described_class.from_hash(manifest)
      end

      it "uses performance optimizations during to_response" do
        no_fonts do
          # Create a manifest object without going through from_hash
          # to avoid consuming the optimization in from_hash
          manifest = described_class.from_yaml({ "Andale Mono" => "Regular" }.to_yaml)

          # Install the font first so that to_response doesn't short-circuit
          # (to_response returns early if fonts aren't installed)
          example_font_to_fontist("AndaleMo.TTF")

          # Now test that to_response also uses optimizations
          # We verify this by checking that read_only_mode is enabled on the index
          # which is set by with_performance_optimizations
          expect(Fontist::Indexes::FontistIndex.instance).to receive(:read_only_mode).and_call_original
          expect(Fontist::Indexes::UserIndex.instance).to receive(:read_only_mode).and_call_original
          expect(Fontist::Indexes::SystemIndex.instance).to receive(:read_only_mode).and_call_original

          manifest.to_response
        end
      end
    end
  end
end
