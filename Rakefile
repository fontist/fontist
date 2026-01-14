require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "net/http"
require "uri"
require "fileutils"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec]

desc "Download macOS font catalog XML files from Apple"
task :download_macos_catalogs do
  catalogs_dir = "spec/fixtures/macos_catalogs"
  FileUtils.mkdir_p(catalogs_dir)

  catalogs = {
    "com_apple_MobileAsset_Font3" => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font3/com_apple_MobileAsset_Font3.xml",
    "com_apple_MobileAsset_Font4" => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font4/com_apple_MobileAsset_Font4.xml",
    "com_apple_MobileAsset_Font5" => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font5/com_apple_MobileAsset_Font5.xml",
    "com_apple_MobileAsset_Font6" => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font6/com_apple_MobileAsset_Font6.xml",
    "com_apple_MobileAsset_Font7" => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font7/com_apple_MobileAsset_Font7.xml",
    "com_apple_MobileAsset_Font8" => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font8/com_apple_MobileAsset_Font8.xml",
  }

  catalogs.each do |name, url|
    target_file = File.join(catalogs_dir, "#{name}.xml")

    if File.exist?(target_file)
      puts "Skipping #{name}.xml (already exists)"
      next
    end

    puts "Downloading #{name}.xml from #{url}..."

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "Fontist Rake Task"

    response = http.request(request)
    File.write(target_file, response.body)

    puts "  ✓ Downloaded #{name}.xml"
  end

  puts "\nDownloaded all macOS font catalogs to #{catalogs_dir}/"
end



