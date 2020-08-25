require_relative "otfinfo/otfinfo_requirement"
require_relative "text_helper"

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
          .map { |x| x.split(":", 2) }
          .map { |x| x.map { |y| Fontist::Import::TextHelper.cleanup(y) } }
          .to_h
      end
    end
  end
end
