#!/usr/bin/env ruby
# frozen_string_literal: true

# Entry point of the tebako-packed fontist (copied to bin/fontist by
# script/tebako/stage.sh).
#
# tebako installs the locked dependencies as gems inside the package; only
# fontist itself sits at a path, so it goes on the load path directly.
# bundler/setup is not used: bundler chdirs into path gems, and the packed
# filesystem refuses that.
#
# Libraries loaded through FFI (yeptris, leptris, ...) are opened with the
# host's dlopen, which cannot see inside the package. Each one is copied
# once to a host cache keyed by its content, and FFI is handed that copy.

require "digest"
require "fileutils"
require "ffi"

module FontistPackedNativeLibraries
  PACKAGE_ROOT = "/__tfs__/"

  def self.cache_root
    home = ENV["FONTIST_PATH"] || File.join(Dir.home, ".fontist")
    File.join(home, "tebako-native")
  end

  def self.host_path(name)
    return name unless name.is_a?(String) && name.start_with?(PACKAGE_ROOT)
    return name unless File.file?(name)

    bytes = File.binread(name)
    dir = File.join(cache_root, Digest::SHA256.hexdigest(bytes)[0, 16])
    target = File.join(dir, File.basename(name))
    write_once(target, bytes) unless File.file?(target)
    target
  end

  def self.write_once(target, bytes)
    FileUtils.mkdir_p(File.dirname(target))
    partial = "#{target}.#{Process.pid}.partial"
    File.binwrite(partial, bytes)
    File.chmod(0o755, partial)
    File.rename(partial, target)
  end

  # An Array argument is a list of alternatives (the first that loads wins),
  # so the nesting is kept: only the names inside are rewritten.
  def self.rewrite(name)
    name.is_a?(Array) ? name.map { |n| rewrite(n) } : host_path(name)
  end

  def ffi_lib(*names)
    super(*names.map { |name| FontistPackedNativeLibraries.rewrite(name) })
  end
end

FFI::Library.prepend(FontistPackedNativeLibraries)

# leptris also opens libleptris from its compiled extension, which consults
# LEPTRIS_LIB_PATH and then package paths the host cannot open. Two copies
# of the library loaded side by side crash it, so both loaders are pointed
# at the same host copy. yeptris reads YEPTRIS_LIB_PATH the same way.
{
  "leptris" => %w[LEPTRIS_LIB_PATH libleptris],
  "yeptris" => %w[YEPTRIS_LIB_PATH libyeptris],
}.each do |gem_name, (variable, basename)|
  next if ENV[variable]

  spec = Gem::Specification.find_all_by_name(gem_name).max_by(&:version)
  next unless spec

  library = Dir.glob(
    File.join(spec.full_gem_path, "**", "#{basename}.{dylib,so,dll}"),
  ).min
  ENV[variable] = FontistPackedNativeLibraries.host_path(library) if library
end

$LOAD_PATH.unshift(File.expand_path("../vendor/fontist/lib", __dir__))
load File.expand_path("../vendor/fontist/exe/fontist", __dir__)
