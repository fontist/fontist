require "spec_helper"

RSpec.describe Fontist::Resources::WindowsFodResource do
  let(:capability_name) { "Language.Fonts.Jpan~~~und-JPAN~0.0.1.0" }
  let(:resource) do
    Struct.new(:capability_name).new(capability_name)
  end

  subject(:fod_resource) { described_class.new(resource) }

  describe "#files" do
    context "when capability is already installed" do
      before do
        allow(Fontist::Utils::System).to receive(:run_powershell)
          .with("(Get-WindowsCapability -Online -Name '#{capability_name}').State")
          .and_return(Fontist::Utils::System::PowerShellResult.new(stdout: "Installed\n", stderr: "", success: true))
      end

      it "yields paths for existing font files" do
        fonts_dir = Dir.mktmpdir
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("windir").and_return(nil)
        allow(ENV).to receive(:[]).with("SystemRoot").and_return(nil)

        # Override system_fonts_dir via windir
        allow(ENV).to receive(:[]).with("windir").and_return(fonts_dir)

        # Create a fake font file
        font_path = File.join(fonts_dir, "Fonts", "Meiryo.ttc")
        FileUtils.mkdir_p(File.dirname(font_path))
        FileUtils.touch(font_path)

        yielded_paths = []
        fod_resource.files(["Meiryo.ttc"]) do |path|
          yielded_paths << path
        end

        expect(yielded_paths).to contain_exactly(font_path)
      ensure
        FileUtils.rm_rf(fonts_dir)
      end

      it "does not yield paths for missing font files" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("windir").and_return("/nonexistent")
        allow(ENV).to receive(:[]).with("SystemRoot").and_return(nil)

        yielded_paths = []
        fod_resource.files(["NonExistent.ttf"]) do |path|
          yielded_paths << path
        end

        expect(yielded_paths).to be_empty
      end
    end

    context "when capability needs installation" do
      before do
        allow(Fontist::Utils::System).to receive(:run_powershell)
          .with("(Get-WindowsCapability -Online -Name '#{capability_name}').State")
          .and_return(Fontist::Utils::System::PowerShellResult.new(stdout: "NotPresent\n", stderr: "", success: true))

        allow(Fontist).to receive_message_chain(:ui, :say)
      end

      it "installs the capability via PowerShell" do
        install_result = Fontist::Utils::System::PowerShellResult.new(stdout: "", stderr: "", success: true)
        expect(Fontist::Utils::System).to receive(:run_powershell)
          .with("Add-WindowsCapability -Online -Name '#{capability_name}'")
          .and_return(install_result)

        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("windir").and_return("/nonexistent")
        allow(ENV).to receive(:[]).with("SystemRoot").and_return(nil)

        fod_resource.files([]) {}
      end

      it "raises WindowsFodInstallError on failure" do
        install_result = Fontist::Utils::System::PowerShellResult.new(
          stdout: "",
          stderr: "Access denied",
          success: false,
        )
        allow(Fontist::Utils::System).to receive(:run_powershell)
          .with("Add-WindowsCapability -Online -Name '#{capability_name}'")
          .and_return(install_result)

        expect do
          fod_resource.files([]) {}
        end.to raise_error(Fontist::Errors::WindowsFodInstallError) do |error|
          expect(error.message).to include(capability_name)
          expect(error.message).to include("Access denied")
          expect(error.capability_name).to eq(capability_name)
        end
      end
    end
  end
end
