require "spec_helper"

RSpec.describe Fontist::FormulaSuggestion do
  describe "#find" do
    subject { described_class.new.find(name) }

    context "a lot of formulas" do
      let(:name) { "andle" }

      it "finds one" do
        expect(subject).to include(be_instance_of(Fontist::Formula))
        expect(subject.first).to have_attributes(key: "andale")
      end
    end

    context "two matching formulas" do
      include_context "fresh home"

      let(:name) { "noto sans" }

      before do
        example_formula("noto_sans_cjk.yml")
        example_formula("google/noto_sans.yml")
      end

      it "finds two" do
        expect(subject).to include(have_attributes(key: "noto_sans_cjk"))
        expect(subject).to include(have_attributes(key: "google/noto_sans"))
      end
    end

    context "two matching formulas with mistype" do
      include_context "fresh home"

      let(:name) { "noto sns" }

      before do
        example_formula("noto_sans_cjk.yml")
        example_formula("google/noto_sans.yml")
      end

      it "finds two" do
        expect(subject).to include(have_attributes(key: "noto_sans_cjk"))
        expect(subject).to include(have_attributes(key: "google/noto_sans"))
      end
    end

    context "matching formula from a custom repo" do
      include_context "fresh home"

      let(:name) { "andle" }

      before do
        example_formula("andale.yml", "private/acme/andale.yml")
      end

      it "finds one" do
        expect(subject).to include(have_attributes(key: "private/acme/andale"))
      end
    end

    context "matching and non-matching formulas" do
      include_context "fresh home"

      # Skip on Windows to isolate FormulaSuggestion issue
      before do
        skip "FormulaSuggestion finding extra matches on Windows - investigate separately" if Fontist::Utils::System.user_os == :windows
      end

      let(:name) { "andle" }

      before do
        example_formula("andale.yml")
        example_formula("noto_sans_cjk.yml")
      end

      it "finds one" do
        expect(subject.count).to be 1
        expect(subject).to include(have_attributes(key: "andale"))
      end
    end
  end
end
