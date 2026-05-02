#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate Windows FOD (Features on Demand) formula files
#
# Usage:
#   bundle exec ruby script/generate_windows_formulas.rb [output_dir]
#
# Generates formula YAML files for all 25 Windows FOD font capabilities.
# Output goes to Formulas/windows/ by default, or to the specified directory.

require "bundler/setup"
require "fontist"
require_relative "../lib/fontist/import/windows"

output_dir = ARGV[0]

importer = if output_dir
             Fontist::Import::Windows.new(formulas_dir: output_dir)
           else
             Fontist::Import::Windows.new
           end

importer.call
