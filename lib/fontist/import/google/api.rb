module Fontist
  module Import
    module Google
      class Api
        class << self
          def items
            db["items"]
          end

          def db
            @db ||= JSON.parse(Net::HTTP.get(URI(url)))
          end

          def url
            "https://www.googleapis.com/webfonts/v1/webfonts?key=#{api_key}"
          end

          def api_key
            Fontist.google_fonts_key
          end
        end
      end
    end
  end
end
