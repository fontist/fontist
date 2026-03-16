#!/usr/bin/env ruby
# frozen_string_literal: true

# Validate Windows FOD capabilities against live Windows system
#
# Usage:
#   bundle exec ruby script/validate_windows_fod_ci.rb
#
# This script:
# 1. Loads fod_capabilities.yml
# 2. Queries Windows for real FOD capabilities via PowerShell
# 3. Compares our YAML capability names against what Windows reports
# 4. For installed capabilities, checks that expected font files exist
# 5. Exits 0 on success, 1 on critical mismatches

require "yaml"

FONTS_DIR = 'C:\Windows\Fonts'
YAML_PATH = File.expand_path(
  "../lib/fontist/import/windows/fod_capabilities.yml",
  __dir__,
)

def main
  unless Gem.win_platform?
    puts "SKIP: Not running on Windows"
    exit 0
  end

  puts "=== Windows FOD Capability Validation ==="
  puts ""

  yaml_caps = load_yaml_capabilities
  live_caps = query_live_capabilities

  puts "YAML capabilities: #{yaml_caps.size}"
  puts "Live capabilities: #{live_caps.size}"
  puts ""

  matched, missing_from_yaml, extra_in_yaml = compare(yaml_caps, live_caps)

  print_results(matched, missing_from_yaml, extra_in_yaml)

  errors = check_installed_fonts(yaml_caps, live_caps)

  puts ""
  summarize(matched, missing_from_yaml, extra_in_yaml, errors)
end

def load_yaml_capabilities
  data = YAML.safe_load(File.read(YAML_PATH))
  data.fetch("capabilities", {})
rescue StandardError => e
  puts "ERROR: Failed to load YAML: #{e.message}"
  exit 1
end

def query_live_capabilities
  output = `powershell -NoProfile -Command "Get-WindowsCapability -Online -Name 'Language.Fonts.*' | Select-Object Name, State | ConvertTo-Csv -NoTypeInformation"`

  unless $?.success?
    puts "ERROR: PowerShell command failed (exit #{$?.exitstatus})"
    exit 1
  end

  caps = {}
  output.each_line do |line|
    line = line.strip.delete('"')
    next if line.empty? || line.start_with?("Name")

    name, state = line.split(",", 2)
    caps[name] = state if name && state
  end
  caps
end

def compare(yaml_caps, live_caps)
  yaml_names = yaml_caps.keys.to_set
  live_names = live_caps.keys.to_set

  matched = yaml_names & live_names
  missing_from_yaml = live_names - yaml_names
  extra_in_yaml = yaml_names - live_names

  [matched, missing_from_yaml, extra_in_yaml]
end

def print_results(matched, missing_from_yaml, extra_in_yaml)
  puts "=== Matched (#{matched.size}) ==="
  matched.sort.each { |name| puts "  OK: #{name}" }

  if missing_from_yaml.any?
    puts ""
    puts "=== Missing from our YAML (#{missing_from_yaml.size}) ==="
    missing_from_yaml.sort.each { |name| puts "  MISSING: #{name}" }
  end

  if extra_in_yaml.any?
    puts ""
    puts "=== Extra in our YAML (#{extra_in_yaml.size}) ==="
    extra_in_yaml.sort.each { |name| puts "  EXTRA: #{name}" }
  end
end

def check_installed_fonts(yaml_caps, live_caps)
  installed = live_caps.select { |_, state| state == "Installed" }
  return [] if installed.empty?

  puts ""
  puts "=== Font File Checks for Installed Capabilities ==="

  errors = []

  installed.each_key do |cap_name|
    cap_data = yaml_caps[cap_name]
    next unless cap_data

    fonts = cap_data.fetch("fonts", {})
    fonts.each do |family_name, data|
      files = data.fetch("files", [])
      files.each do |filename|
        path = File.join(FONTS_DIR, filename)
        if File.exist?(path)
          puts "  OK: #{filename} (#{family_name})"
        else
          puts "  MISSING: #{filename} (#{family_name}) — expected at #{path}"
          errors << "#{cap_name}: #{filename} not found"
        end
      end
    end
  end

  errors
end

def summarize(matched, missing_from_yaml, extra_in_yaml, font_errors)
  puts "========================================="
  puts "  Validation Summary"
  puts "========================================="
  puts "  Capability matches:      #{matched.size}"
  puts "  Missing from our YAML:   #{missing_from_yaml.size}"
  puts "  Extra in our YAML:       #{extra_in_yaml.size}"
  puts "  Font file errors:        #{font_errors.size}"
  puts ""

  if missing_from_yaml.any?
    puts "WARNING: #{missing_from_yaml.size} capabilities exist on Windows but not in our YAML."
    puts "  Consider adding them to fod_capabilities.yml"
    puts ""
  end

  if extra_in_yaml.any?
    puts "WARNING: #{extra_in_yaml.size} capabilities in our YAML not found on this Windows version."
    puts "  These may be version-specific or renamed."
    puts ""
  end

  if font_errors.any?
    puts "WARNING: #{font_errors.size} font files missing for installed capabilities."
    font_errors.each { |e| puts "  - #{e}" }
    puts ""
  end

  # Exit 1 only if we have zero matches (indicates a fundamental problem)
  if matched.empty? && (missing_from_yaml.any? || extra_in_yaml.any?)
    puts "CRITICAL: No capability names matched — our YAML may be completely wrong."
    exit 1
  end

  puts "Validation passed."
  exit 0
end

main
