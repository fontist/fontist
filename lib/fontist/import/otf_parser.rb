require_relative "otfinfo/otfinfo_requirement"

module Fontist
  module Import
    class OtfParser
      REQUIREMENTS = {
        otfinfo: Fontist::Import::Otfinfo::OtfinfoRequirement.new,
      }.freeze

      def initialize(path)
        @path = path
      end

      def call
        text = REQUIREMENTS[:otfinfo].call(@path)
        text.split("\n")
          .select { |x| x.include?(":") }
          .map { |x| x.split(":", 2).map { |y| cleanup(y) } }
          .to_h
      end

      private

      def cleanup(text)
        text.gsub("\r\n", "\n")
          .gsub("\r", "\n")
          .strip
      end
    end
  end
end
