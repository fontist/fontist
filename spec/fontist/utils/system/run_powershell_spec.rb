require "spec_helper"

RSpec.describe Fontist::Utils::System, ".run_powershell" do
  describe "PowerShellResult" do
    it "returns success? as true when successful" do
      result = Fontist::Utils::System::PowerShellResult.new(
        stdout: "Installed", stderr: "", success: true,
      )
      expect(result).to be_success
      expect(result.stdout).to eq("Installed")
      expect(result.stderr).to eq("")
    end

    it "returns success? as false when unsuccessful" do
      result = Fontist::Utils::System::PowerShellResult.new(
        stdout: "", stderr: "error", success: false,
      )
      expect(result).not_to be_success
    end
  end

  describe ".run_powershell" do
    it "returns a failed result when powershell.exe is not found" do
      allow(Open3).to receive(:capture3)
        .and_raise(Errno::ENOENT, "powershell.exe")

      result = Fontist::Utils::System.run_powershell("Get-Date")
      expect(result).not_to be_success
      expect(result.stderr).to include("powershell.exe")
    end
  end
end
