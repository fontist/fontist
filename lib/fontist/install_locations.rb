module Fontist
  module InstallLocations
    autoload :BaseLocation, "#{__dir__}/install_locations/base_location"
    autoload :FontistLocation, "#{__dir__}/install_locations/fontist_location"
    autoload :SystemLocation, "#{__dir__}/install_locations/system_location"
    autoload :UserLocation, "#{__dir__}/install_locations/user_location"
  end
end
