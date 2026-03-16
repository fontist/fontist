module Fontist
  module Resources
    class WindowsFodResource
      def initialize(resource, options = {})
        @resource = resource
        @options = options
      end

      def files(source_names, &block)
        install_capability!

        source_names.each do |filename|
          path = File.join(system_fonts_dir, filename)
          yield path if File.exist?(path)
        end
      end

      private

      def install_capability!
        cap_name = @resource.capability_name
        return if capability_installed?(cap_name)

        Fontist.ui.say("Installing Windows font capability: #{cap_name}")
        result = Utils::System.run_powershell(
          "Add-WindowsCapability -Online -Name '#{cap_name}'",
        )
        unless result.success?
          raise Errors::WindowsFodInstallError.new(cap_name, result.stderr)
        end
      end

      def capability_installed?(name)
        result = Utils::System.run_powershell(
          "(Get-WindowsCapability -Online -Name '#{name}').State",
        )
        result.stdout.strip == "Installed"
      end

      def system_fonts_dir
        windir = ENV["windir"] || ENV["SystemRoot"] || "C:/Windows"
        File.join(windir, "Fonts")
      end
    end
  end
end
