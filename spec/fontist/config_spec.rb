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
      context "fonts install path is specified in config" do
        it "installs fonts in that dir" do
          example_formula("andale.yml")

          Dir.mktmpdir do |dir|
            Fontist::Config.instance.set(:fonts_path, dir)

            command = Fontist::Font.install("andale mono", confirmation: "yes")
            expect(command).to include(File.join(dir, "AndaleMo.TTF"))
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
end
