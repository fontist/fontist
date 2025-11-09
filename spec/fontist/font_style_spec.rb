require "spec_helper"

RSpec.describe Fontist::FontStyle do
  describe ".from_yaml" do
    let(:single_style) do
      <<~YAML
        ---
        family_name: Source Code Pro
        type: Medium
        full_name: Source Code Pro Medium
        post_script_name: SourceCodePro-Medium
        version: 2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
        description: Lorem ipsum
        copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
          with Reserved Font Name ‘Source’.
        font: SourceCodePro-Medium.ttf
      YAML
    end

    it "round-trips" do
      model = described_class.from_yaml(single_style)
      expect(model.to_yaml).to eq(single_style)
    end
  end
end
