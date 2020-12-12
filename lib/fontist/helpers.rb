module Fontist
  module Helpers
    def self.parse_to_object(data)
      JSON.parse(data.to_json, object_class: OpenStruct)
    end
  end
end
