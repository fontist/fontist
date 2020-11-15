module Fontist
  module Utils
    module Dsl
      class Font
        REQUIRED_ATTRIBUTES = %i[family_name
                                 style
                                 full_name
                                 filename].freeze

        attr_reader :attributes

        def initialize(attributes)
          REQUIRED_ATTRIBUTES.each do |required_attribute|
            unless attributes[required_attribute]
              raise(Fontist::Errors::MissingAttributeError.new(
                      "Missing attribute: #{required_attribute}"
                    ))
            end
          end

          self.attributes = attributes
        end

        def attributes=(attrs)
          @attributes = { family_name: attrs[:family_name],
                          type: attrs[:style],
                          full_name: attrs[:full_name],
                          post_script_name: attrs[:post_script_name],
                          version: attrs[:version],
                          description: attrs[:description],
                          copyright: attrs[:copyright],
                          font: attrs[:filename],
                          source_font: attrs[:source_filename] }
        end
      end
    end
  end
end
