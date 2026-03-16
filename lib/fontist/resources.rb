module Fontist
  module Resources
    autoload :AppleCDNResource, "#{__dir__}/resources/apple_cdn_resource"
    autoload :ArchiveResource, "#{__dir__}/resources/archive_resource"
    autoload :GoogleResource, "#{__dir__}/resources/google_resource"
    autoload :WindowsFodResource, "#{__dir__}/resources/windows_fod_resource"
  end
end
