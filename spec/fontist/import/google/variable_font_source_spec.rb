require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Fontist::Import::Google::VariableFontSource do
  let(:fixture) { File.expand_path("../../../fixtures/google_vf", __dir__) }

  describe "through the Github data source" do
    around do |example|
      Dir.mktmpdir("gfonts") do |dir|
        @repo = dir
        FileUtils.cp_r(Dir.glob("#{fixture}/*"), dir)
        system("git init -q && git add . && " \
               "git -c user.email=t@t -c user.name=t commit -qm init",
               chdir: dir, exception: true)
        @sha = Dir.chdir(dir) { `git rev-parse HEAD`.strip }
        example.run
      end
    end

    it "pins the variable file URLs to the clone's commit" do
      family = Fontist::Import::Google::DataSources::Github
        .new(source_path: @repo).fetch_family("Vf Demo")

      expect(family.variable_source.urls.first).to eq(
        "https://raw.githubusercontent.com/google/fonts/#{@sha}/ofl/vfdemo/" \
        "VfDemo[wdth,wght].ttf",
      )
    end
  end

  it "has no variable source for a static family" do
    path = File.expand_path("../../../fixtures/google/ofl/roboto/METADATA.pb",
                            __dir__)
    metadata = Fontist::Import::Google::Models::Metadata.from_file(path)

    expect(described_class.from_metadata(metadata, directory: "ofl/roboto",
                                                   commit: "a" * 40)).to be_nil
  end
end
