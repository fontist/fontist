require "spec_helper"

RSpec.describe Fontist::Resource do
  describe "sha256 form handling" do
    it "keeps a single digest as a scalar" do
      resource = described_class.from_yaml("sha256: b5b9e15791a177715fa5")

      expect(resource.sha256).to eq("b5b9e15791a177715fa5")
    end

    it "preserves a per-mirror digest list as written" do
      resource = described_class.from_yaml("sha256:\n- aaaa\n- bbbb")

      expect(resource.sha256).to eq(%w[aaaa bbbb])
    end

    it "round-trips a scalar digest without the list wrapper" do
      digest = "b5b9e15791a177715fa5"
      resource = described_class.from_yaml("sha256: #{digest}")
      redumped = described_class.from_yaml(resource.to_yaml)

      expect(redumped.sha256).to eq(digest)
    end

    # A list digest on a scalar attribute serializes flow-style, so a
    # regenerated formula would normalize the per-mirror digests. The
    # corpus is never rewritten by fontist; the two list-form formulas
    # keep parsing with both digests intact.
    it "keeps both digests accessible when a list is re-parsed" do
      resource = described_class.from_yaml("sha256:\n- aaaa\n- bbbb")

      expect(resource.sha256.map(&:to_s)).to contain_exactly("aaaa", "bbbb")
    end
  end
end
