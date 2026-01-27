require "spec_helper"

RSpec.describe Fontist::Config do
  include_context "fresh home"

  let(:conf) { described_class.instance }

  describe "#set" do
    it "sets by symbol" do
      conf.set(:open_timeout, 20)
      expect(conf.values[:open_timeout]).to eq 20
    end

    context "non-existing option" do
      it "throws InvalidConfigAttributeError error" do
        expect { conf.set(:non_existent_key, 10) }
          .to raise_error(Fontist::Errors::InvalidConfigAttributeError)
      end
    end
  end

  describe "#delete" do
    it "deletes by symbol" do
      conf.set(:open_timeout, 20)
      conf.delete(:open_timeout)
      expect(conf.values[:open_timeout])
        .to eq conf.default_values[:open_timeout]
    end
  end

  describe "options" do
    around do |example|
      values = conf.instance_variable_get(:@custom_values).dup

      example.run

      conf.instance_variable_set(:@custom_values, values)
    end

    describe "fonts_path" do
      context "fonts install path is specified in config",
              :platform_test_fonts do
        it "installs fonts in that dir" do
          skip "Skipped on Windows due to safe_mktmpdir retry incompatibility" if Fontist::Utils::System.user_os == :windows

          example_formula(test_formula)

          safe_mktmpdir do |dir|
            Fontist::Config.instance.set(:fonts_path, dir)

            command = Fontist::Font.install(test_font_downcase,
                                            confirmation: "yes")
            # Command returns array of paths, check one is in the dir
            expect(command.first).to start_with(dir)
          end
        end
      end

      context "fonts install path uses the home symbol" do
        it "expands the home symbol to an absolute path" do
          Fontist::Config.instance.set(:fonts_path, "~/fonts")

          expect(Fontist.fonts_path.to_s).to eq File.join(Dir.home, "fonts")
        end
      end

      context "relative path is used and then current dir is changed" do
        it "uses a dir for fonts path when option was set" do
          Dir.mktmpdir do |dir|
            expanded_dir = Dir.chdir(dir) do
              Fontist::Config.instance.set(:fonts_path, "fonts123")

              File.expand_path(".")
            end

            expect(Fontist.fonts_path.to_s)
              .to eq File.join(expanded_dir, "fonts123")
          end
        end
      end
    end
  end

  describe ".fonts_install_location" do
    after do
      ENV.delete("FONTIST_INSTALL_LOCATION")
      described_class.reset
    end

    context "with default (no ENV, no config)" do
      it "returns :fontist" do
        expect(described_class.fonts_install_location).to eq(:fontist)
      end
    end

    context "with ENV variable set" do
      it "returns :fontist when ENV is 'fontist'" do
        ENV["FONTIST_INSTALL_LOCATION"] = "fontist"
        expect(described_class.fonts_install_location).to eq(:fontist)
      end

      it "returns :user when ENV is 'user'" do
        ENV["FONTIST_INSTALL_LOCATION"] = "user"
        expect(described_class.fonts_install_location).to eq(:user)
      end

      it "returns :system when ENV is 'system'" do
        ENV["FONTIST_INSTALL_LOCATION"] = "system"
        expect(described_class.fonts_install_location).to eq(:system)
      end

      it "handles fontist-library alias" do
        ENV["FONTIST_INSTALL_LOCATION"] = "fontist-library"
        expect(described_class.fonts_install_location).to eq(:fontist)
      end

      it "handles case-insensitive values" do
        ENV["FONTIST_INSTALL_LOCATION"] = "USER"
        expect(described_class.fonts_install_location).to eq(:user)
      end

      it "handles underscore vs hyphen" do
        ENV["FONTIST_INSTALL_LOCATION"] = "fontist_library"
        expect(described_class.fonts_install_location).to eq(:fontist)
      end

      it "defaults to :fontist for invalid values" do
        # Stub the error message
        allow(Fontist.ui).to receive(:error)

        ENV["FONTIST_INSTALL_LOCATION"] = "invalid"
        expect(described_class.fonts_install_location).to eq(:fontist)
      end
    end

    context "with config file value set" do
      around do |example|
        values = conf.instance_variable_get(:@custom_values).dup
        example.run
        conf.instance_variable_set(:@custom_values, values)
        described_class.reset
      end

      it "returns config value when no ENV set" do
        conf.set(:fonts_install_location, "user")
        expect(described_class.fonts_install_location).to eq(:user)
      end

      it "returns :system from config" do
        conf.set(:fonts_install_location, "system")
        expect(described_class.fonts_install_location).to eq(:system)
      end
    end

    context "with both ENV and config set" do
      around do |example|
        values = conf.instance_variable_get(:@custom_values).dup
        example.run
        conf.instance_variable_set(:@custom_values, values)
        described_class.reset
      end

      it "ENV takes precedence over config" do
        conf.set(:fonts_install_location, "user")
        ENV["FONTIST_INSTALL_LOCATION"] = "system"

        expect(described_class.fonts_install_location).to eq(:system)
      end
    end
  end

  describe ".set_fonts_install_location" do
    around do |example|
      values = conf.instance_variable_get(:@custom_values).dup
      example.run
      conf.instance_variable_set(:@custom_values, values)
      described_class.reset
    end

    it "sets fontist location" do
      described_class.set_fonts_install_location(:fontist)
      # Check immediately before around block restores
      expect(described_class.instance.custom_values[:fonts_install_location]).to eq("fontist")
    end

    it "sets user location" do
      described_class.set_fonts_install_location(:user)
      expect(described_class.instance.custom_values[:fonts_install_location]).to eq("user")
    end

    it "sets system location" do
      described_class.set_fonts_install_location(:system)
      expect(described_class.instance.custom_values[:fonts_install_location]).to eq("system")
    end

    it "accepts string values" do
      described_class.set_fonts_install_location("user")
      expect(described_class.instance.custom_values[:fonts_install_location]).to eq("user")
    end

    it "handles fontist-library alias" do
      described_class.set_fonts_install_location("fontist-library")
      expect(described_class.instance.custom_values[:fonts_install_location]).to eq("fontist")
    end

    it "handles case-insensitive values" do
      described_class.set_fonts_install_location("USER")
      expect(described_class.instance.custom_values[:fonts_install_location]).to eq("user")
    end

    it "handles underscore vs hyphen" do
      described_class.set_fonts_install_location("fontist_library")
      expect(described_class.instance.custom_values[:fonts_install_location]).to eq("fontist")
    end

    it "raises error for invalid values" do
      expect do
        described_class.set_fonts_install_location("invalid")
      end.to raise_error(Fontist::Errors::InvalidConfigAttributeError,
                         /Invalid location/)
    end

    it "persists the value" do
      described_class.set_fonts_install_location(:user)

      # Verify it was persisted by checking custom_values immediately
      expect(described_class.instance.custom_values[:fonts_install_location]).to eq("user")
    end
  end
end
