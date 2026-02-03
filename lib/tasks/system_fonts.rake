namespace :system_fonts do
  desc "Capture system fonts from current platform to fixtures"
  task capture: :ensure_catalogs do
    require "fontist"
    require "yaml"
    require "set"

    # Get the current platform
    platform = Fontist::Utils::System.user_os
    puts "Capturing system fonts for platform: #{platform}"

    # Build the system index to scan all fonts
    index = Fontist::Indexes::SystemIndex.instance
    index.rebuild(verbose: false)

    # Read the index file
    index_path = Fontist.system_index_path
    unless File.exist?(index_path)
      puts "ERROR: System index not found at #{index_path}"
      puts "Run 'fontist index rebuild system' first"
      exit 1
    end

    index_data = YAML.load_file(index_path)

    # Extract font families from the array of font entries
    # Each entry has family_name and optionally preferred_family_name
    font_families = Set.new
    index_data.each do |entry|
      # Use preferred_family_name if available (more specific), otherwise family_name
      family = entry["preferred_family_name"] || entry["family_name"]
      font_families.add(family) if family
    end

    font_families = font_families.to_a.sort

    # Build a structured output
    output = {
      "platform" => platform.to_s,
      "captured_at" => Time.now.utc.iso8601,
      "font_families" => font_families,
      "count" => font_families.count,
    }

    # Write to fixtures
    fixtures_dir = File.join(Fontist.root_path, "spec", "fixtures",
                             "system_fonts")
    FileUtils.mkdir_p(fixtures_dir)

    output_file = File.join(fixtures_dir, "#{platform}_system_fonts.yml")
    File.write(output_file, YAML.dump(output))

    puts "✓ Captured #{font_families.count} font families to:"
    puts "  #{output_file}"
    puts "\nFirst 20 fonts:"
    font_families.first(20).each { |f| puts "  - #{f}" }
    puts "  ... and #{font_families.count - 20} more" if font_families.count > 20
  end

  desc "List all captured system font fixtures"
  task list: :ensure_catalogs do
    require "fontist"

    fixtures_dir = File.join(Fontist.root_path, "spec", "fixtures",
                             "system_fonts")
    Dir.glob(File.join(fixtures_dir, "*.yml")).each do |file|
      data = YAML.load_file(file)
      puts "#{File.basename(file, '.ycol')}:"
      puts "  Platform: #{data['platform']}"
      puts "  Captured: #{data['captured_at']}"
      puts "  Fonts: #{data['count']}"
      puts ""
    end
  end
end
