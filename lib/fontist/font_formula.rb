module Fontist
  class FontFormula
    include Singleton
    extend Fontist::Utils::Dsl
    include Fontist::Utils::ZipExtractor
    include Fontist::Utils::ExeExtractor
    include Fontist::Utils::MsiExtractor
    include Fontist::Utils::SevenZipExtractor

    attr_accessor :license, :license_url, :license_required, :copyright
    attr_accessor :key, :homepage, :description, :options, :temp_resource

    def font_list
      @font_list ||= []
    end

    def resources
      @resources ||= {}
    end

    def fonts
      @fonts ||= font_list.uniq
    end

    def extract_font_styles(options)
      extract_from_file(options) ||
        extract_from_collection(options) || default_font
    end

    def reinitialize
      @downloaded = false
      @matched_fonts = []
    end

    def self.fetch_font(name, confirmation:)
      if instance.license_required && confirmation.downcase != "yes"
        raise(Fontist::Errors::LicensingError)
      end

      instance.reinitialize
      instance.install_font(name, confirmation)
    end

    def install_font(name, confirmation)
      run_in_temp_dir { extract }
      matched_fonts_uniq = matched_fonts.flatten.uniq
      matched_fonts_uniq.empty? ? nil : matched_fonts_uniq
    end

    private

    attr_reader :downloaded, :matched_fonts

    def resource(name, &block)
      source = resources[name]
      block_given? ? yield(source) : source
    end

    def fonts_path
      @fonts_path = Fontist.fonts_path
    end

    def default_font
      [{ type: "Regular", font: temp_resource[:filename] }]
    end

    def run_in_temp_dir(&block)
      Dir.mktmpdir(nil, Dir.tmpdir) do |dir|
        @temp_dir = Pathname.new(dir)

        yield
        @temp_dir = nil
      end
    end

    def extract_from_file(options)
      styles = options.fetch(:match_styles_from_file, [])

      unless styles.empty?
        styles.map do |attributes|
          Fontist::Utils::Dsl::Font.new(attributes).attributes
        end
      end
    end

    def match_fonts(fonts_paths, font_name)
      filenames = filenames_by_font_name(font_name)
      paths = search_for_filenames(fonts_paths, filenames)
      @matched_fonts.push(*paths)

      paths
    end

    def filenames_by_font_name(font_name)
      fonts.map do |f|
        if f[:name].casecmp?(font_name)
          f[:styles].map do |s|
            s[:font]
          end
        end
      end.flatten.compact
    end

    def search_for_filenames(paths, filenames)
      paths.select do |path|
        filenames.any? do |filename|
          File.basename(path) == filename
        end
      end
    end

    def extract_from_collection(options)
      styles = options.fetch(:extract_styles_from_collection, [])

      unless styles.empty?
        styles.map do |attributes|
          filenames = temp_resource.select { |k, _|
            %i( filename source_filename ).include?(k)
          }
          Fontist::Utils::Dsl::CollectionFont.new(attributes.merge(filenames))
            .attributes
        end
      end
    end

    def download_file(source)
      url = source[:urls].first
      Fontist.ui.say(%(Downloading font "#{key}" from #{url}))

      downloaded_file = Fontist::Utils::Downloader.download(
        url,
        sha: source[:sha256],
        file_size: source[:file_size],
        progress_bar: is_progress_bar_enabled
      )

      @downloaded = true
      downloaded_file
    end

    def is_progress_bar_enabled
      options.nil? ? true : options.fetch(:progress_bar, true)
    end

    def font_file?(filename)
      source_files.include?(filename)
    end

    def source_files
      @source_files ||= fonts.flat_map do |font|
        font[:styles].map do |style|
          style[:source_font] || style[:font]
        end
      end
    end

    def target_filename(source_filename)
      target_filenames[source_filename]
    end

    def target_filenames
      @target_filenames ||= fonts.flat_map do |font|
        font[:styles].map do |style|
          source = style[:source_font] || style[:font]
          target = style[:font]
          [source, target]
        end
      end.to_h
    end
  end
end
