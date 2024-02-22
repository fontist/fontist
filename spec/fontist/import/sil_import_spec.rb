require "spec_helper"

RSpec.describe "Fontist::Import::SilImport", slow: true, dev: true do
  let(:command) { Fontist::Import::SilImport.new.call }
  let(:formulas_repo_path) { Pathname.new(create_tmp_dir) }

  let(:fonts_under_test) { ["Apparatus SIL"] }

  it "finds archive links and calls CreateFormula" do
    VCR.use_cassette("sil_import") do
      require "fontist/import/sil_import"

      allow(Fontist).to receive(:formulas_repo_path)
        .and_return(formulas_repo_path)

      Dir.mktmpdir do |index_dir|
        allow(Fontist).to receive(:formula_index_dir)
          .and_return(Pathname.new(index_dir))

        allow_any_instance_of(Fontist::Import::SilImport)
          .to receive(:font_links).and_wrap_original do |m, *args|
            m.call(*args).select do |tag|
              fonts_under_test.include?(tag.content)
            end
          end

        received_count = 0
        allow_any_instance_of(Fontist::Import::CreateFormula)
          .to receive(:call) { received_count += 1 }

        command

        expect(received_count).to be 1

        expect(Fontist.formulas_path.join("sil")).to exist
      end
    end
  end
end
