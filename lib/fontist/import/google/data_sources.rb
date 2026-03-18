module Fontist
  module Import
    module Google
      module DataSources
        autoload :Base, "#{__dir__}/data_sources/base"
        autoload :Github, "#{__dir__}/data_sources/github"
        autoload :Ttf, "#{__dir__}/data_sources/ttf"
        autoload :Vf, "#{__dir__}/data_sources/vf"
        autoload :Woff2, "#{__dir__}/data_sources/woff2"
      end
    end
  end
end
