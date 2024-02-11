module Fontist
  module Helper
    def stub_fontist_path_to_temp_path
      allow(Fontist).to receive(:fontist_path).and_return(
        Fontist.root_path.join("spec", "fixtures"),
      )
    end

    def fresh_fonts_and_formulas
      fresh_fontist_home do
        stub_system_fonts

        FileUtils.mkdir_p(Fontist.fonts_path)
        FileUtils.mkdir_p(Fontist.formulas_path)

        yield

        Fontist::Index.reset_cache
      end
    end

    def fresh_fontist_home
      Dir.mktmpdir do |dir|
        orig_home = Fontist.default_fontist_path
        allow(Fontist).to receive(:default_fontist_path)
          .and_return(Pathname.new(dir))

        yield dir

        allow(Fontist).to receive(:default_fontist_path).and_return(orig_home)
      end
    end

    def fresh_main_repo(branch = "main")
      remote_main_repo(branch) do |dir|
        Git.clone(dir, Fontist.formulas_repo_path, depth: 1)

        yield dir
      end
    end

    def remote_main_repo(branch = "main")
      Dir.mktmpdir do |dir|
        FileUtils.mkdir(File.join(dir, "Formulas"))
        FileUtils.touch(File.join(dir, "Formulas", ".keep"))

        init_repo(dir, branch) do |git|
          git.add(File.join("Formulas", ".keep"))
        end

        yield dir
      end
    end

    def init_repo(dir, branch)
      git = Git.init(dir)
      git.checkout(branch, new_branch: true)
      git.config("user.name", "Test")
      git.config("user.email", "test@example.com")

      yield git

      git.commit("msg")
    end

    def no_fonts_and_formulas(&block)
      no_fonts do
        no_formulas(&block)
      end
    end

    def no_fonts(&block)
      if block_given?
        stub_fonts_path_to_new_path do
          stub_system_fonts_path_to_new_path(&block)
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
      pattern = File.join(path,
                          "**",
                          "*.{[t|T][t|T][f|F],[o|O][t|T][f|F],[t|T][t|T][c|C]}")
      paths = 4.times.map { { "paths" => [pattern] } } # rubocop:disable Performance/TimesMap, Metrics/LineLength, avoid aliases in YAML
      { "system" => %w[linux windows macos unix].zip(paths).to_h }
    end

    def stub_system_fonts(system_file = nil)
      allow(Fontist).to receive(:system_file_path).and_return(
        system_file || Fontist.root_path.join("spec", "fixtures", "system.yml"),
      )

      disable_system_font_paths_caching
    end

    def disable_system_font_paths_caching
      allow(SystemFont).to receive(:system_font_paths) do
        SystemFont.load_system_font_paths
      end
    end

    def cleanup_fonts
      cleanup_system_fonts
      cleanup_fontist_fonts
    end

    def cleanup_system_fonts
      raise("System dir is not stubbed") unless @system_dir

      FileUtils.rm_rf(@system_dir)
      @system_dir = nil
    end

    def cleanup_fontist_fonts
      raise("Fontist dir is not stubbed") unless @fontist_dir

      FileUtils.rm_rf(@fontist_dir)
      @fontist_dir = nil
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

    def stub_license_agreement_prompt_with_exception
      allow(Thor::LineEditor).to receive(:readline).and_raise(Errno::EBADF)
    end

    def fixtures_dir(&block)
      Dir.chdir(Fontist.root_path.join("spec", "fixtures"), &block)
    end

    def stub_font_file(filename, dir = nil)
      dir ||= Fontist.fonts_path.to_s
      FileUtils.touch(File.join(dir, filename))
    end

    def font_files
      Dir.entries(Fontist.fonts_path) - %w[. ..]
    end

    def font_file(filename)
      Pathname.new(Fontist.fonts_path.join(filename))
    end

    def font_path(filename, dir = nil)
      dir ||= Fontist.fonts_path.to_s
      File.join(dir, filename)
    end

    def system_font_path(filename)
      raise("System dir is not stubbed") unless @system_dir

      File.join(@system_dir, filename)
    end

    def fontist_font_path(filename)
      raise("Fontist dir is not stubbed") unless @fontist_dir

      File.join(@fontist_dir, filename)
    end

    def create_tmp_dir
      dir = Dir.mktmpdir
      Dir.glob(dir).first # expand the ~1 suffix on Windows
    end

    def example_font(filename)
      example_font_to(filename, Fontist.fonts_path)
    end

    def example_font_to_system(filename)
      raise("System dir is not stubbed") unless @system_dir

      example_font_to(filename, @system_dir)
    end

    def example_font_to_fontist(filename)
      raise("Fontist dir is not stubbed") unless @fontist_dir

      example_font_to(filename, @fontist_dir)
    end

    def example_font_to(filename, dir)
      example_path = examples_font_path(filename)
      target_path = File.join(dir, filename)
      FileUtils.cp(example_path, target_path)
    end

    def examples_font_path(filename)
      File.join("spec", "examples", "fonts", filename)
    end

    def examples_formula_path(filename)
      File.join("spec", "examples", "formulas", filename)
    end

    def no_formulas(&block)
      previous = Fontist.formulas_repo_path
      @formulas_repo_path = create_formulas_repo
      allow(Fontist).to receive(:formulas_repo_path)
        .and_return(@formulas_repo_path)

      rebuilt_index(&block)

      allow(Fontist).to receive(:formulas_repo_path).and_return(previous)
      @formulas_repo_path = nil
    end

    def create_formulas_repo
      dir = Pathname.new(Dir.mktmpdir)
      FileUtils.mkdir(dir.join("Formulas"))
      dir
    end

    def rebuilt_index
      Dir.mktmpdir do |dir|
        original = Fontist.formula_index_dir
        allow(Fontist).to receive(:formula_index_dir)
          .and_return(Pathname.new(dir))
        Fontist::Index.rebuild

        yield

        Fontist::Index.reset_cache
        allow(Fontist).to receive(:formula_index_dir).and_return(original)
      end
    end

    def formula_repo_with(example_formula, branch = "main")
      Dir.mktmpdir do |dir|
        example_formula_to(example_formula, dir)

        init_repo(dir, branch) do |git|
          git.add(example_formula)
        end

        yield dir
      end
    end

    def add_to_formula_repo(dir, example_formula)
      example_formula_to(example_formula, dir)
      add_to_repo(dir, example_formula)
    end

    def create_new_file_in_repo(repo_dir, file_to_touch)
      FileUtils.touch(File.join(repo_dir, file_to_touch))
      add_to_repo(repo_dir, file_to_touch)
    end

    def add_to_repo(repo_dir, file_to_add)
      git = Git.open(repo_dir)
      git.add(file_to_add)
      git.commit("msg")
    end

    def example_formula(path, target_path = nil)
      example_path = File.join("spec", "examples", "formulas", path)
      absolute_target_path = Fontist.formulas_path.join(target_path || path)
      FileUtils.mkdir_p(File.dirname(absolute_target_path))
      FileUtils.cp(example_path, absolute_target_path)

      Fontist::Index.rebuild
    end

    def example_formula_to(filename, dir)
      example_path = File.join("spec", "examples", "formulas", filename)
      target_path = File.join(dir, filename)
      FileUtils.cp(example_path, target_path)
    end

    def example_manifest(name)
      File.join("spec", "examples", "manifests", name)
    end

    def stub_env(name, value)
      prev = ENV[name]
      ENV[name] = value
      yield
      ENV[name] = prev
    end

    def stub_system_index_path
      previous_path = Fontist.system_index_path

      path = File.join(create_tmp_dir, "system_index.yml")
      allow(Fontist).to receive(:system_index_path).and_return(path)

      yield path

      allow(Fontist).to receive(:system_index_path).and_return(previous_path)

      path
    end

    def avoid_cache(*urls)
      Utils::Cache.new.tap do |cache|
        paths = urls.map do |url|
          [url, cache.delete(url)]
        end

        yield

        paths.each do |url, path|
          cache.set(url, path) if path
        end
      end
    end

    def with_option(option)
      original = Fontist.send("#{option}?")
      Fontist.send("#{option}=", true)

      yield

      Fontist.send("#{option}=", original)
    end

    def patch_yml(path, data, *dig_path)
      key = dig_path.pop
      formula = YAML.load_file(path)
      formula.dig(*dig_path)[key] = data
      File.write(path, YAML.dump(formula))
    end

    def restore_default_settings
      Fontist.interactive = false
    end
  end
end
