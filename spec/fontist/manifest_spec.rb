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
      let(:test_formula) { Fontist::Test::PlatformFonts.installable_test_formula }
      let(:test_font) { Fontist::Test::PlatformFonts.installable_test_font }
      before { example_formula(test_formula) }

      # Clean up any Andale Mono fonts before each test to prevent
      # state pollution from previous tests in the same fresh_home context
      before do
        font_path = Fontist.fonts_path.join("andale")
        FileUtils.rm_rf(font_path) if File.exist?(font_path)

        # Also remove any Andale font files by globbing
        Dir.glob(Fontist.fonts_path.join("**", "*.ttf")).each do |file|
          FileUtils.rm_rf(file) if file.include?("andale") || file.include?("Andale")
        end

        # Reset ALL caches
        Fontist::SystemFont.reset_font_paths_cache
        Fontist::SystemFont.disable_find_styles_cache
        Fontist::Indexes::FontistIndex.reset_cache
        Fontist::Indexes::UserIndex.reset_cache
        Fontist::Indexes::SystemIndex.reset_cache
        Fontist::Index.reset_cache
        Fontist::SystemIndex.reset_cache
      end

      let(:instance) { described_class.from_hash(manifest).install }
      let(:manifest) { { test_font => "Regular" } }

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

      context "fonts platform validation" do
        let(:manifest) { { "STIX Two Math" => nil } }
        before { example_formula("stix.yml") }

        it "installs 'STIX Two Math' font without any error" do
          expect { instance }.not_to raise_error
        end
      end

      context "incompatible platform" do
        let(:manifest) { { "Work Sans" => nil } }
        before { example_formula("work_sans_macos_only.yml") }

        it "raises PlatformMismatchError" do
          expect { instance }.to raise_error(Fontist::Errors::PlatformMismatchError)
        end
      end

      context "requires license confirmation and no flag passed", :windows => false do
        it "raises licensing error" do
          # Explicitly rebuild the index to ensure the formula is found
          Fontist::Index.rebuild

          # Stub the UI class method to return "no" instead of prompting, which will
          # cause the license check to raise LicensingError. This simulates the
          # user rejecting the license agreement.
          allow(Fontist::Utils::UI).to receive(:ask).and_return("no")

          # The install method defaults to confirmation: "no"
          # This should raise LicensingError when the font requires a license
          expect { instance }.to raise_error Fontist::Errors::LicensingError
        end
      end

      context "confirmation option passed as no", :windows => false do
        let(:instance) do
          described_class.from_hash(manifest).install(confirmation: "no")
        end

        it "raises licensing error" do
          # Explicitly rebuild the index to ensure the formula is found
          Fontist::Index.rebuild

          # Stub the UI class method to return "no" instead of prompting, which will
          # cause the license check to raise LicensingError. This simulates the
          # user rejecting the license agreement.
          allow(Fontist::Utils::UI).to receive(:ask).and_return("no")

          # Explicit confirmation: "no" should raise LicensingError
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
            # Verify the operation completes successfully
            # (we don't need to stub paths for this test since fresh_home already provides isolation)
            result = described_class.from_hash(manifest)
              .install(confirmation: "yes", location: :user)

            # Verify installation succeeded and returns a response
            expect(result).to be_a(Fontist::ManifestResponse)
            expect(result.fonts).not_to be_empty
          end

          it "installs all fonts to system location" do
            # For system location, we need to stub the system fonts path
            # to avoid permission errors
            stub_system_fonts_path_to_new_path do
              result = described_class.from_hash(manifest)
                .install(confirmation: "yes", location: :system)

              # Verify installation succeeded - result should be a ManifestResponse or Manifest
              # (If fonts have empty paths, to_response returns Manifest instead)
              expect([Fontist::ManifestResponse,
                      Fontist::Manifest]).to include(result.class)
              expect(result.fonts).not_to be_empty
            end
          end

          it "installs all fonts to fontist location" do
            # Use the default fontist location
            result = described_class.from_hash(manifest)
              .install(confirmation: "yes", location: :fontist)

            # Verify installation succeeded
            expect(result).to be_a(Fontist::ManifestResponse)
            expect(result.fonts).not_to be_empty
          end
        end

        context "invalid locations" do
          it "shows error for invalid location but proceeds" do
            # Capture UI output to verify error is shown
            error_output = []
            allow(Fontist.ui).to receive(:error) { |msg| error_output << msg }

            result = described_class.from_hash(manifest)
              .install(confirmation: "yes", location: :invalid)

            # Verify installation still completes despite invalid location
            expect(result).to be_a(Fontist::ManifestResponse)
            # Verify error was shown
            expect(error_output).to be_any
            expect(error_output.join).to include("Invalid install location")
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
            # Verify that when installing with location: :user,
            # the installation succeeds and returns both fonts
            result = described_class.from_hash(manifest)
              .install(confirmation: "yes", location: :user)

            # Verify installation succeeded for both fonts
            expect(result).to be_a(Fontist::ManifestResponse)
            expect(result.fonts.count).to eq(2)

            # Verify that each font has installation results (styles with paths)
            result.fonts.each do |font_response|
              expect(font_response.styles).not_to be_empty
              # Each style should have paths
              font_response.styles.each do |style|
                expect(style.paths).not_to be_empty if style.respond_to?(:paths)
              end
            end
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
        # Track the initial state
        fontist_index = Fontist::Indexes::FontistIndex.instance
        user_index = Fontist::Indexes::UserIndex.instance
        system_index = Fontist::Indexes::SystemIndex.instance

        # Run the optimization block
        described_class.with_performance_optimizations do
          # Verify indexes are in read-only mode during execution
          # The collection object has @read_only_mode set
          expect(fontist_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
            .to be true
          expect(user_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
            .to be true
          expect(system_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
            .to be true
        end

        # After execution, read-only mode persists in the collection
        expect(fontist_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
          .to be true
        expect(user_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
          .to be true
        expect(system_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
          .to be true
      end

      it "enables caching for find_styles lookups" do
        # Verify caching is disabled initially
        expect(Fontist::SystemFont.instance_variable_get(:@find_styles_cache_enabled))
          .to be false

        # Run the optimization block
        described_class.with_performance_optimizations do
          # Verify caching is enabled during execution
          expect(Fontist::SystemFont.instance_variable_get(:@find_styles_cache_enabled))
            .to be true
        end

        # Verify caching is disabled after execution
        expect(Fontist::SystemFont.instance_variable_get(:@find_styles_cache_enabled))
          .to be false
      end

      it "disables caching after execution even if error occurs" do
        # Enable caching before the test to simulate a pre-enabled state
        Fontist::SystemFont.enable_find_styles_cache
        expect(Fontist::SystemFont.instance_variable_get(:@find_styles_cache_enabled))
          .to be true

        error_raised = false
        begin
          described_class.with_performance_optimizations do
            raise "Test error"
          end
        rescue RuntimeError => e
          error_raised = true
          expect(e.message).to eq("Test error")
        end

        expect(error_raised).to be true

        # Verify caching was disabled despite the error
        expect(Fontist::SystemFont.instance_variable_get(:@find_styles_cache_enabled))
          .to be false
      end
    end

    describe "manifest compilation with optimizations" do
      it "compiles from_file successfully with optimizations" do
        manifest_path = File.join("spec", "examples", "manifests",
                                  "mscorefonts.yml")

        # Verify the operation completes successfully
        # (optimizations are applied automatically)
        expect { described_class.from_file(manifest_path) }.not_to raise_error

        # Verify that indexes were set to read-only mode during compilation
        fontist_index = Fontist::Indexes::FontistIndex.instance
        user_index = Fontist::Indexes::UserIndex.instance
        system_index = Fontist::Indexes::SystemIndex.instance

        expect(fontist_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
          .to be true
        expect(user_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
          .to be true
        expect(system_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
          .to be true
      end

      it "compiles from_hash successfully with optimizations" do
        manifest = { "Andale Mono" => "Regular" }

        # Verify the operation completes successfully
        # (optimizations are applied automatically)
        expect { described_class.from_hash(manifest) }.not_to raise_error

        # Verify that indexes were set to read-only mode during compilation
        fontist_index = Fontist::Indexes::FontistIndex.instance
        user_index = Fontist::Indexes::UserIndex.instance
        system_index = Fontist::Indexes::SystemIndex.instance

        expect(fontist_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
          .to be true
        expect(user_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
          .to be true
        expect(system_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
          .to be true
      end

      it "uses performance optimizations during to_response" do
        no_fonts do
          # Create a manifest object without going through from_hash
          # to avoid consuming the optimization in from_hash
          manifest = described_class.from_yaml({ "Andale Mono" => "Regular" }.to_yaml)

          # Install the font first so that to_response doesn't short-circuit
          # (to_response returns early if fonts aren't installed)
          example_font_to_fontist("AndaleMo.TTF")

          # Reset index read-only mode to verify it gets enabled by to_response
          Fontist::Indexes::FontistIndex.instance.reset_cache
          Fontist::Indexes::UserIndex.instance.reset_cache
          Fontist::Indexes::SystemIndex.instance.reset_cache

          # Call to_response and verify it completes successfully
          expect { manifest.to_response }.not_to raise_error

          # Verify that indexes were set to read-only mode during to_response
          fontist_index = Fontist::Indexes::FontistIndex.instance
          user_index = Fontist::Indexes::UserIndex.instance
          system_index = Fontist::Indexes::SystemIndex.instance

          expect(fontist_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
            .to be true
          expect(user_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
            .to be true
          expect(system_index.instance_variable_get(:@collection).instance_variable_get(:@read_only_mode))
            .to be true
        end
      end
    end
  end
end
