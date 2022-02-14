module Fontist
  class Fontconfig
    def self.update
      new.update
    end

    def self.remove(options = {})
      new(options).remove
    end

    def initialize(options = {})
      @options = options
    end

    def update
      ensure_fontconfig_installed
      create_config
      regenerate_fontconfig_cache
    end

    def remove
      return handle_file_not_found unless config_exists?

      regenerate_fontconfig_cache if fontconfig_installed?
      remove_config
    end

    private

    def ensure_fontconfig_installed
      raise Errors::FontconfigNotFoundError unless fontconfig_installed?
    end

    def fontconfig_installed?
      Utils::System.fontconfig_installed?
    end

    def create_config
      return if File.exist?(config_path)

      FileUtils.mkdir_p(File.dirname(config_path))
      File.write(config_path, config_content)
    end

    def config_path
      File.join(xdg_config_home, "fontconfig", "conf.d", "10-fontist.conf")
    end

    def xdg_config_home
      ENV["XDG_CONFIG_HOME"] || File.join(Dir.home, ".config")
    end

    def config_content
      <<~CONTENT
        <?xml version='1.0'?>
        <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
        <fontconfig>
          <dir>#{Fontist.fonts_path}</dir>
        </fontconfig>
      CONTENT
    end

    def regenerate_fontconfig_cache
      Helpers.run("fc-cache -f")
    end

    def ensure_file_exists
      return if @options[:force]

      raise Errors::FontconfigFileNotFoundError unless File.exist?(config_path)
    end

    def config_exists?
      File.exist?(config_path)
    end

    def handle_file_not_found
      return if @options[:force]

      raise Errors::FontconfigFileNotFoundError
    end

    def remove_config
      FileUtils.rm(config_path)
    end
  end
end
