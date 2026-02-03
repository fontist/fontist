module Fontist
  class ManifestCLI < Thor
    include CLI::ClassOptions

    desc "install MANIFEST", "Install fonts from MANIFEST (yaml)"
    option :accept_all_licenses, type: :boolean,
                                 aliases: ["--confirm-license", :a],
                                 desc: "Accept all license agreements"
    option :hide_licenses, type: :boolean,
                           aliases: :h,
                           desc: "Hide license texts"
    option :location,
           type: :string, aliases: :l,
           enum: ["fontist", "user", "system"],
           desc: "Install location: fontist (default), user, system"
    def install(manifest)
      handle_class_options(options)
      instance = Fontist::Manifest.from_file(manifest)
      paths = instance.install(
        confirmation: options[:accept_all_licenses] ? "yes" : "no",
        hide_licenses: options[:hide_licenses],
        location: options[:location]&.to_sym,
      )
      print_yaml(paths.to_hash)
      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end

    desc "locations MANIFEST", "Get locations of fonts from MANIFEST (yaml)"
    option :show_timing, type: :boolean, aliases: :t,
                         desc: "Show timing information for manifest resolution"
    def locations(manifest)
      handle_class_options(options)

      start_time = Time.now

      paths = Fontist::Manifest.from_file(manifest, locations: true)

      resolve_time = Time.now - start_time

      print_yaml(paths.to_hash)

      if options[:show_timing]
        puts
        puts Paint["⏱ Timing:", :cyan, :bright]
        puts Paint["  Manifest resolution time: ",
                   :white] + Paint["#{resolve_time.round(3)}s", :yellow,
                                   :bright]
        puts Paint["  Fonts in manifest:         ",
                   :white] + Paint[paths.fonts.size.to_s, :yellow]
      end

      CLI::STATUS_SUCCESS
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end

    private

    def print_yaml(object)
      Fontist.ui.say(YAML.dump(object))
    end

    def handle_error(exception)
      status, mode, message = CLI::ERROR_TO_STATUS[exception.class]
      raise exception unless status

      text = if message && mode == :overwrite
               message
             elsif message
               "#{exception.message} #{message}"
             else
               exception.message
             end

      error(text, status)
    end

    def error(message, status)
      Fontist.ui.error(message)
      status
    end
  end
end
