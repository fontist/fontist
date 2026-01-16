RSpec.describe Fontist::Utils::System do
  describe "platform override functionality" do
    after do
      ENV.delete("FONTIST_PLATFORM_OVERRIDE")
    end

    describe ".platform_override" do
      it "returns nil when not set" do
        expect(described_class.platform_override).to be_nil
      end

      it "returns ENV value when set" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font7"
        expect(described_class.platform_override).to eq("macos-font7")
      end
    end

    describe ".platform_override?" do
      it "returns false when not set" do
        expect(described_class.platform_override?).to be false
      end

      it "returns true when set" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font7"
        expect(described_class.platform_override?).to be true
      end
    end

    describe ".parse_platform_override" do
      context "with valid macOS framework format" do
        it "parses macos-font3" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font3"
          result = described_class.parse_platform_override

          expect(result).not_to be_nil
          expect(result[:os]).to eq(:macos)
          expect(result[:framework]).to eq(3)
        end

        it "parses macos-font7" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font7"
          result = described_class.parse_platform_override

          expect(result).not_to be_nil
          expect(result[:os]).to eq(:macos)
          expect(result[:framework]).to eq(7)
        end

        it "parses macos-font8" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font8"
          result = described_class.parse_platform_override

          expect(result).not_to be_nil
          expect(result[:os]).to eq(:macos)
          expect(result[:framework]).to eq(8)
        end

        it "handles double-digit framework numbers" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font10"
          result = described_class.parse_platform_override

          expect(result).not_to be_nil
          expect(result[:os]).to eq(:macos)
          expect(result[:framework]).to eq(10)
        end
      end

      context "with valid OS-only format" do
        it "parses macos" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos"
          result = described_class.parse_platform_override

          expect(result).not_to be_nil
          expect(result[:os]).to eq(:macos)
          expect(result[:framework]).to be_nil
        end

        it "parses linux" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "linux"
          result = described_class.parse_platform_override

          expect(result).not_to be_nil
          expect(result[:os]).to eq(:linux)
          expect(result[:framework]).to be_nil
        end

        it "parses windows" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "windows"
          result = described_class.parse_platform_override

          expect(result).not_to be_nil
          expect(result[:os]).to eq(:windows)
          expect(result[:framework]).to be_nil
        end
      end

      context "with invalid format" do
        before do
          # Stub the error message since UI.error is used for warnings
          allow(Fontist.ui).to receive(:error)
        end

        it "returns nil for version number format (old format)" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-10.15"
          result = described_class.parse_platform_override

          expect(result).to be_nil
        end

        it "returns nil for version string" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "12.0"
          result = described_class.parse_platform_override

          expect(result).to be_nil
        end

        it "returns nil for random string" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "invalid"
          result = described_class.parse_platform_override

          expect(result).to be_nil
        end

        it "returns nil for missing framework number" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font"
          result = described_class.parse_platform_override

          expect(result).to be_nil
        end

        it "returns nil for wrong separator" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos_font7"
          result = described_class.parse_platform_override

          expect(result).to be_nil
        end

        it "returns nil for empty string" do
          ENV["FONTIST_PLATFORM_OVERRIDE"] = ""
          result = described_class.parse_platform_override

          expect(result).to be_nil
        end
      end

      it "returns nil when not set" do
        expect(described_class.parse_platform_override).to be_nil
      end
    end

    describe ".user_os with override" do
      it "returns overridden OS when set" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "linux"

        # Clear memoization
        described_class.instance_variable_set(:@user_os, nil)

        expect(described_class.user_os).to eq(:linux)
      end

      it "returns macOS from framework override" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font7"

        # Clear memoization
        described_class.instance_variable_set(:@user_os, nil)

        expect(described_class.user_os).to eq(:macos)
      end

      it "returns windows from override" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "windows"

        # Clear memoization
        described_class.instance_variable_set(:@user_os, nil)

        expect(described_class.user_os).to eq(:windows)
      end

      it "uses actual OS when override is invalid" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "invalid"

        # Stub the error message
        allow(Fontist.ui).to receive(:error)

        # Clear memoization
        described_class.instance_variable_set(:@user_os, nil)

        # Should fall back to actual detection
        actual_os = described_class.user_os
        expect(%i[macos linux windows unix]).to include(actual_os)
      end

      it "uses actual OS when no override" do
        # Clear memoization
        described_class.instance_variable_set(:@user_os, nil)

        actual_os = described_class.user_os
        expect(%i[macos linux windows unix]).to include(actual_os)
      end
    end

    describe ".macos_version with override" do
      it "returns min version for overridden framework" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font7"

        # Clear memoization
        described_class.instance_variable_set(:@macos_version, nil)

        expect(described_class.macos_version).to eq("12.0")
      end

      it "returns min version for Font3" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font3"

        # Clear memoization
        described_class.instance_variable_set(:@macos_version, nil)

        expect(described_class.macos_version).to eq("10.12")
      end

      it "returns min version for Font8" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font8"

        # Clear memoization
        described_class.instance_variable_set(:@macos_version, nil)

        expect(described_class.macos_version).to eq("26.0")
      end

      it "uses actual version when override has no framework" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos"

        # Clear memoization
        described_class.instance_variable_set(:@macos_version, nil)

        # Should use actual sw_vers or return nil
        version = described_class.macos_version
        expect(version).to be_nil.or(match(/^\d+\.\d+/))
      end
    end

    describe ".catalog_version_for_macos with override" do
      it "returns overridden framework version" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font7"

        expect(described_class.catalog_version_for_macos).to eq(7)
      end

      it "returns framework 3 when overridden" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font3"

        expect(described_class.catalog_version_for_macos).to eq(3)
      end

      it "returns framework 8 when overridden" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font8"

        expect(described_class.catalog_version_for_macos).to eq(8)
      end

      it "uses actual macOS version when override has no framework" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos"

        # Clear memoization
        described_class.instance_variable_set(:@macos_version, nil)

        # Should use MacosFrameworkMetadata.framework_for_macos
        # Result depends on actual system or returns nil
        result = described_class.catalog_version_for_macos
        expect(result).to be_nil.or(be_an(Integer))
      end

      it "uses actual detection when no override" do
        # Clear memoization
        described_class.instance_variable_set(:@macos_version, nil)

        result = described_class.catalog_version_for_macos
        expect(result).to be_nil.or(be_an(Integer))
      end
    end

    describe "integration with real platform values" do
      it "allows testing Linux behavior on macOS" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "linux"

        # Clear memoization
        described_class.instance_variable_set(:@user_os, nil)

        expect(described_class.user_os).to eq(:linux)
        expect(described_class.macos_version).to be_nil
        expect(described_class.catalog_version_for_macos).to be_nil
      end

      it "allows testing Windows behavior on Linux" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "windows"

        # Clear memoization
        described_class.instance_variable_set(:@user_os, nil)

        expect(described_class.user_os).to eq(:windows)
        expect(described_class.macos_version).to be_nil
      end

      it "allows testing specific macOS version on any platform" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font7"

        # Clear memoization
        described_class.instance_variable_set(:@user_os, nil)
        described_class.instance_variable_set(:@macos_version, nil)

        expect(described_class.user_os).to eq(:macos)
        expect(described_class.macos_version).to eq("12.0")
        expect(described_class.catalog_version_for_macos).to eq(7)
      end
    end
  end
end
