module Fontist
  module Import
    class << self
      def name_to_filename(name)
        "#{name.downcase.gsub(' ', '_')}.yml"
      end
    end
  end
end
