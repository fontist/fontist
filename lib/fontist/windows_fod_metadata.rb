require "yaml"

module Fontist
  # Metadata for Windows Features on Demand (FOD) font capabilities
  #
  # Provides lookup methods to map between FOD capability names and
  # their associated font families/filenames.
  class WindowsFodMetadata
    DATA_PATH = File.expand_path("import/windows/fod_capabilities.yml", __dir__)

    class << self
      # Reverse lookup: font family name -> capability name
      #
      # @param font_name [String] The font family name (e.g., "Meiryo")
      # @return [String, nil] The capability name or nil if not found
      def capability_for_font(font_name)
        reverse_map[font_name.downcase]
      end

      # Get all font families for a capability
      #
      # @param cap_name [String] The capability name
      # @return [Hash, nil] Hash of font family names to their metadata
      def fonts_for_capability(cap_name)
        cap = metadata.dig("capabilities", cap_name)
        cap&.fetch("fonts", nil)
      end

      # Get the description for a capability
      #
      # @param cap_name [String] The capability name
      # @return [String, nil] The description
      def description_for_capability(cap_name)
        metadata.dig("capabilities", cap_name, "description")
      end

      # Flat list of all FOD font family names
      #
      # @return [Array<String>] All font family names
      def all_font_names
        metadata["capabilities"].flat_map do |_cap, data|
          data["fonts"].keys
        end
      end

      # List of all capability names
      #
      # @return [Array<String>] All capability names
      def all_capabilities
        metadata["capabilities"].keys
      end

      # Raw parsed YAML metadata
      #
      # @return [Hash] The parsed YAML data
      def metadata
        @metadata ||= YAML.safe_load(File.read(DATA_PATH))
      end

      # Reset cached metadata (for testing)
      # @api private
      def reset_cache
        @metadata = nil
        @reverse_map = nil
      end

      private

      # Build reverse lookup map: lowercase font name -> capability name
      def reverse_map
        @reverse_map ||= begin
          map = {}
          metadata["capabilities"].each do |cap_name, data|
            data["fonts"].each_key do |font_name|
              map[font_name.downcase] = cap_name
            end
          end
          map
        end
      end
    end
  end
end
