require "spec_helper"

RSpec.describe Fontist::InstallLocations::BaseLocation do
  # Create a concrete test class since BaseLocation is abstract
  let(:mock_index) do
    instance_double("TestIndex",
                    find: nil,
                    font_exists?: false,
                    add_font: nil,
                    remove_font: nil)
  end

  let(:test_location_class) do
    index_instance = mock_index
    Class.new(described_class) do
      define_method(:location_type) { :test }
      define_method(:base_path) { Pathname.new("/tmp/test") }
      define_method(:index) { index_instance }
    end
  end

  let(:formula) do
    instance_double(Fontist::Formula, key: "test")
  end

  let(:location) { test_location_class.new(formula) }

  describe "abstract methods" do
    it "raises NotImplementedError for base_path" do
      location = described_class.new(formula)
      expect { location.base_path }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for location_type" do
      location = described_class.new(formula)
      expect { location.location_type }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for index" do
      location = described_class.new(formula)
      expect { location.send(:index) }.to raise_error(NotImplementedError)
    end
  end

  describe "#font_path" do
    it "returns full path by joining base_path and filename" do
      path = location.font_path("Roboto-Regular.ttf")
      expect(path.to_s).to eq("/tmp/test/Roboto-Regular.ttf")
    end

    it "handles different filenames" do
      expect(location.font_path("Font.otf").to_s).to eq("/tmp/test/Font.otf")
      expect(location.font_path("Font.woff2").to_s).to eq("/tmp/test/Font.woff2")
    end
  end

  describe "#managed_location?" do
    it "defaults to true" do
      expect(location.send(:managed_location?)).to be true
    end
  end

  describe "#requires_elevated_permissions?" do
    it "defaults to false" do
      expect(location.requires_elevated_permissions?).to be false
    end
  end

  describe "#permission_warning" do
    it "defaults to nil" do
      expect(location.permission_warning).to be_nil
    end
  end

  describe "#font_exists?" do
    it "delegates to index" do
      index = location.send(:index)
      expect(index).to receive(:font_exists?).with("/tmp/test/Font.ttf")

      location.font_exists?("Font.ttf")
    end

    it "returns true when index reports font exists" do
      allow(location.send(:index)).to receive(:font_exists?).and_return(true)
      expect(location.font_exists?("Font.ttf")).to be true
    end

    it "returns false when index reports font not exists" do
      allow(location.send(:index)).to receive(:font_exists?).and_return(false)
      expect(location.font_exists?("Font.ttf")).to be false
    end
  end

  describe "#find_fonts" do
    it "delegates to index.find" do
      index = location.send(:index)
      expect(index).to receive(:find).with("Roboto", "Regular")

      location.find_fonts("Roboto", "Regular")
    end

    it "works without style parameter" do
      index = location.send(:index)
      expect(index).to receive(:find).with("Arial", nil)

      location.find_fonts("Arial")
    end
  end

  describe "#generate_unique_filename" do
    it "adds -fontist suffix when file doesn't exist" do
      allow(File).to receive(:exist?).and_return(false)

      filename = location.send(:generate_unique_filename, "Roboto-Regular.ttf")
      expect(filename).to eq("Roboto-Regular-fontist.ttf")
    end

    it "adds -fontist-2 when -fontist already exists" do
      allow(File).to receive(:exist?).with(Pathname.new("/tmp/test/Roboto-Regular-fontist.ttf")).and_return(true)
      allow(File).to receive(:exist?).with(Pathname.new("/tmp/test/Roboto-Regular-fontist-2.ttf")).and_return(false)

      filename = location.send(:generate_unique_filename, "Roboto-Regular.ttf")
      expect(filename).to eq("Roboto-Regular-fontist-2.ttf")
    end

    it "increments counter until unique filename found" do
      allow(File).to receive(:exist?).with(Pathname.new("/tmp/test/Roboto-Regular-fontist.ttf")).and_return(true)
      allow(File).to receive(:exist?).with(Pathname.new("/tmp/test/Roboto-Regular-fontist-2.ttf")).and_return(true)
      allow(File).to receive(:exist?).with(Pathname.new("/tmp/test/Roboto-Regular-fontist-3.ttf")).and_return(true)
      allow(File).to receive(:exist?).with(Pathname.new("/tmp/test/Roboto-Regular-fontist-4.ttf")).and_return(false)

      filename = location.send(:generate_unique_filename, "Roboto-Regular.ttf")
      expect(filename).to eq("Roboto-Regular-fontist-4.ttf")
    end

    it "preserves file extension" do
      allow(File).to receive(:exist?).and_return(false)

      filename = location.send(:generate_unique_filename, "Font.otf")
      expect(filename).to eq("Font-fontist.otf")
    end
  end

  describe "#install_font" do
    let(:source_path) { "/tmp/source/Roboto-Regular.ttf" }
    let(:target_filename) { "Roboto-Regular.ttf" }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:cp)
      allow(Fontist.ui).to receive(:say)
      allow(Fontist.ui).to receive(:warn)
    end

    context "when font doesn't exist" do
      before do
        allow(location).to receive(:font_exists?).and_return(false)
      end

      it "performs simple installation" do
        expect(FileUtils).to receive(:mkdir_p).with(Pathname.new("/tmp/test"))
        expect(FileUtils).to receive(:cp).with(source_path,
                                               Pathname.new("/tmp/test/Roboto-Regular.ttf"))

        location.install_font(source_path, target_filename)
      end

      it "updates index" do
        index = location.send(:index)
        expect(index).to receive(:add_font).with("/tmp/test/Roboto-Regular.ttf")

        location.install_font(source_path, target_filename)
      end

      it "returns installed path" do
        result = location.install_font(source_path, target_filename)
        expect(result).to eq("/tmp/test/Roboto-Regular.ttf")
      end
    end

    context "when font exists in managed location" do
      before do
        allow(location).to receive(:font_exists?).and_return(true)
        allow(location).to receive(:managed_location?).and_return(true)
      end

      it "replaces existing font" do
        expect(FileUtils).to receive(:cp).with(source_path,
                                               Pathname.new("/tmp/test/Roboto-Regular.ttf"))

        location.install_font(source_path, target_filename)
      end

      it "updates index" do
        index = location.send(:index)
        expect(index).to receive(:add_font).with("/tmp/test/Roboto-Regular.ttf")

        location.install_font(source_path, target_filename)
      end
    end

    context "when font exists in non-managed location" do
      before do
        allow(location).to receive(:font_exists?).and_return(true)
        allow(location).to receive(:managed_location?).and_return(false)
        allow(location).to receive(:generate_unique_filename).and_return("Roboto-Regular-fontist.ttf")
        allow(File).to receive(:exist?).and_return(false)
      end

      it "generates unique filename" do
        expect(location).to receive(:generate_unique_filename).with("Roboto-Regular.ttf")

        location.install_font(source_path, target_filename)
      end

      it "installs with unique name" do
        expect(FileUtils).to receive(:cp).with(source_path,
                                               Pathname.new("/tmp/test/Roboto-Regular-fontist.ttf"))

        location.install_font(source_path, target_filename)
      end

      it "shows educational warning" do
        expect(Fontist.ui).to receive(:say) do |message|
          expect(message).to include("DUPLICATE FONT")
          expect(message).to include("unique name")
        end

        location.install_font(source_path, target_filename)
      end

      it "returns new path with unique filename" do
        result = location.install_font(source_path, target_filename)
        expect(result).to eq("/tmp/test/Roboto-Regular-fontist.ttf")
      end
    end
  end

  describe "#uninstall_font" do
    let(:filename) { "Roboto-Regular.ttf" }

    context "when font exists" do
      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:delete)
      end

      it "deletes the file" do
        expect(File).to receive(:delete).with(Pathname.new("/tmp/test/Roboto-Regular.ttf"))

        location.uninstall_font(filename)
      end

      it "updates index" do
        index = location.send(:index)
        expect(index).to receive(:remove_font).with("/tmp/test/Roboto-Regular.ttf")

        location.uninstall_font(filename)
      end

      it "returns deleted path" do
        result = location.uninstall_font(filename)
        expect(result).to eq("/tmp/test/Roboto-Regular.ttf")
      end
    end

    context "when font doesn't exist" do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "doesn't delete anything" do
        expect(File).not_to receive(:delete)

        location.uninstall_font(filename)
      end

      it "returns nil" do
        result = location.uninstall_font(filename)
        expect(result).to be_nil
      end
    end
  end

  describe "platform-specific warning examples" do
    it "returns correct macOS user example" do
      allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)

      example = location.send(:platform_user_managed_example)
      expect(example).to eq("~/Library/Fonts/fontist/")
    end

    it "returns correct Linux user example" do
      allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)

      example = location.send(:platform_user_managed_example)
      expect(example).to eq("~/.local/share/fonts/fontist/")
    end

    it "returns correct Windows user example" do
      allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)

      example = location.send(:platform_user_managed_example)
      expect(example).to eq("%LOCALAPPDATA%/Microsoft/Windows/Fonts/fontist/")
    end

    it "returns correct macOS system example" do
      allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)

      example = location.send(:platform_system_managed_example)
      expect(example).to eq("/Library/Fonts/fontist/")
    end

    it "returns correct Linux system example" do
      allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)

      example = location.send(:platform_system_managed_example)
      expect(example).to eq("/usr/local/share/fonts/fontist/")
    end

    it "returns correct Windows system example" do
      allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)

      example = location.send(:platform_system_managed_example)
      expect(example).to eq("%windir%/Fonts/fontist/")
    end
  end
end
