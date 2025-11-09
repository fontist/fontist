require "spec_helper"

RSpec.describe Fontist::FontModel do
  describe ".from_yaml" do
    let(:single_style) do
      <<~YAML
        ---
        name: Cambria
        styles:
        - family_name: Cambria
          type: Regular
          full_name: Cambria
      YAML
    end

    it "parses a single style" do
      font_model = described_class.from_yaml(single_style)
      expect(font_model.to_yaml).to eq(single_style)
    end

    let(:multiple_styles) do
      <<~YAML
        ---
        name: Source Code Pro
        styles:
        - family_name: Source Code Pro
          type: Regular
          full_name: Source Code Pro
          post_script_name: SourceCodePro-Regular
          version: 2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-Regular.ttf
        - family_name: Source Code Pro
          type: Medium Italic
          full_name: Source Code Pro Medium Italic
          post_script_name: SourceCodePro-MediumIt
          version: 1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-MediumIt.ttf
        - family_name: Source Code Pro
          type: Italic
          full_name: Source Code Pro Italic
          post_script_name: SourceCodePro-It
          version: 1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-It.ttf
        - family_name: Source Code Pro
          type: ExtraLight Italic
          full_name: Source Code Pro ExtraLight Italic
          post_script_name: SourceCodePro-ExtraLightIt
          version: 1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-ExtraLightIt.ttf
        - family_name: Source Code Pro
          type: ExtraLight
          full_name: Source Code Pro ExtraLight
          post_script_name: SourceCodePro-ExtraLight
          version: 2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-ExtraLight.ttf
        - family_name: Source Code Pro
          type: Black Italic
          full_name: Source Code Pro Black Italic
          post_script_name: SourceCodePro-BlackIt
          version: 1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-BlackIt.ttf
        - family_name: Source Code Pro
          type: Bold Italic
          full_name: Source Code Pro Bold Italic
          post_script_name: SourceCodePro-BoldIt
          version: 1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-BoldIt.ttf
        - family_name: Source Code Pro
          type: Semibold Italic
          full_name: Source Code Pro Semibold Italic
          post_script_name: SourceCodePro-SemiboldIt
          version: 1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-SemiboldIt.ttf
        - family_name: Source Code Pro
          type: Black
          full_name: Source Code Pro Black
          post_script_name: SourceCodePro-Black
          version: 2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-Black.ttf
        - family_name: Source Code Pro
          type: Bold
          full_name: Source Code Pro Bold
          post_script_name: SourceCodePro-Bold
          version: 2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-Bold.ttf
        - family_name: Source Code Pro
          type: Semibold
          full_name: Source Code Pro Semibold
          post_script_name: SourceCodePro-Semibold
          version: 2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-Semibold.ttf
        - family_name: Source Code Pro
          type: Light Italic
          full_name: Source Code Pro Light Italic
          post_script_name: SourceCodePro-LightIt
          version: 1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-LightIt.ttf
        - family_name: Source Code Pro
          type: Medium
          full_name: Source Code Pro Medium
          post_script_name: SourceCodePro-Medium
          version: 2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-Medium.ttf
        - family_name: Source Code Pro
          type: Light
          full_name: Source Code Pro Light
          post_script_name: SourceCodePro-Light
          version: 2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220
          description: Lorem ipsum
          copyright: Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/),
            with Reserved Font Name ‘Source’.
          font: SourceCodePro-Light.ttf
      YAML
    end

    it "parses multiple styles" do
      font_model = described_class.from_yaml(multiple_styles)
      expect(font_model.to_yaml).to eq(multiple_styles)
    end
  end
end
