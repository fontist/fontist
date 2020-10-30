module Fontist
  module Helper
    def stub_fontist_path_to_temp_path
      allow(Fontist).to receive(:fontist_path).and_return(
        Fontist.root_path.join("spec", "fixtures")
      )
    end

    def no_fonts
      if block_given?
        stub_fonts_path_to_new_path do
          stub_system_fonts_path_to_new_path do
            yield
          end
        end
      else
        stub_fonts_path_to_new_path
        stub_system_fonts_path_to_new_path
      end
    end

    def stub_fonts_path_to_new_path
      @fontist_dir = create_tmp_dir
      allow(Fontist).to receive(:fonts_path)
        .and_return(Pathname.new(@fontist_dir))
      return @fontist_dir unless block_given?

      result = yield @fontist_dir
      cleanup_fontist_fonts
      result
    end

    def stub_system_fonts_path_to_new_path
      @system_dir = create_tmp_dir

      system_file = Tempfile.new
      system_file.write(YAML.dump(system_paths(@system_dir)))
      system_file.close

      stub_system_fonts(system_file)
      return @system_dir unless block_given?

      result = yield @system_dir
      cleanup_system_fonts
      result
    end

    def system_paths(path)
      pattern = File.join(path, "**", "*.{ttf,ttc}")
      paths = Array.new(4, "paths" => [pattern])
      { "system" => %w[linux windows macos unix].zip(paths).to_h }
    end

    def stub_system_fonts(system_file = nil)
      allow(Fontist).to receive(:system_file_path).and_return(
        system_file || Fontist.root_path.join("spec", "fixtures", "system.yml")
      )
    end

    def cleanup_fonts
      cleanup_system_fonts
      cleanup_fontist_fonts
    end

    def cleanup_system_fonts
      raise("System dir is not stubbed") unless @system_dir

      FileUtils.remove_entry(@system_dir)
      @system_dir = nil
    end

    def cleanup_fontist_fonts
      raise("Fontist dir is not stubbed") unless @fontist_dir

      FileUtils.remove_entry(@fontist_dir)
      @fontist_dir = nil
    end

    def stub_system_font(filename)
      raise("System dir is not stubbed") unless @system_dir

      stub_font_file(filename, @system_dir)
    end

    def stub_fontist_font(filename)
      raise("Fontist dir is not stubbed") unless @fontist_dir

      stub_font_file(filename, @fontist_dir)
    end

    def stub_system_font_finder_to_fixture(name)
      allow(Fontist::SystemFont).to receive(:find)
        .and_return(["spec/fixtures/fonts/#{name}"])
    end

    def stub_system_font_to(name)
      allow(Fontist::SystemFont).to receive(:find).and_return([name])
    end

    def stub_license_agreement_prompt_with(confirmation = "yes")
      allow(Fontist.ui).to receive(:ask).and_return(confirmation)
    end

    def fixtures_dir
      Dir.chdir(Fontist.root_path.join("spec", "fixtures")) do
        yield
      end
    end

    def stub_font_file(filename, dir = nil)
      dir ||= Fontist.fonts_path.to_s
      FileUtils.touch(File.join(dir, filename))
    end

    def font_file(filename)
      Pathname.new(Fontist.fonts_path.join(filename))
    end

    def font_path(filename, dir = nil)
      dir ||= Fontist.fonts_path.to_s
      File.join(dir, filename)
    end

    def create_tmp_dir
      dir = Dir.mktmpdir
      Dir.glob(dir).first # expand the ~1 suffix on Windows
    end
  end
end
