require_relative "base_location"

module Fontist
  module InstallLocations
    # Fontist library location (default installation location)
    #
    # This location represents the fontist-managed font library at:
    #   ~/.fontist/fonts/{formula-key}/
    #
    # Characteristics:
    # - Always managed (safe to replace fonts)
    # - Formula-keyed for isolation
    # - No elevated permissions required
    # - Default installation location
    #
    # Example paths:
    #   ~/.fontist/fonts/roboto/Roboto-Regular.ttf
    #   ~/.fontist/fonts/macos/font7/sf_pro/SFPro-Regular.ttf
    class FontistLocation < BaseLocation
      # Returns location type identifier
      # @return [Symbol] :fontist
      def location_type
        :fontist
      end

      # Returns base installation path for this formula
      #
      # Structure: ~/.fontist/fonts/{formula-key}/
      # The formula key provides isolation between different font formulas
      #
      # @return [Pathname] Formula-keyed installation directory
      def base_path
        Fontist.fonts_path.join(formula.key)
      end

      protected

      # Returns the FontistIndex instance
      #
      # This index tracks all fonts installed in the fontist library
      #
      # @return [Indexes::FontistIndex] Singleton index instance
      def index
        @index ||= Fontist::Indexes::FontistIndex.instance
      end

      # Fontist library location is always managed
      #
      # This location is explicitly owned by Fontist, so it's always safe
      # to replace fonts here. Users expect Fontist to manage these files.
      #
      # @return [Boolean] Always true
      def managed_location?
        true
      end
    end
  end
end
