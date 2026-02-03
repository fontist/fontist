# frozen_string_literal: true

# Shared context for tests that need platform-appropriate fonts
#
# This context provides a standardized way to use platform-specific test fonts
# without hardcoding font names in individual tests. It ensures tests work
# consistently across Windows, macOS, and Linux by using fonts that are:
# - NOT pre-installed on the test platform (for installation tests)
# - Appropriate for the platform's font licensing model
#
# Usage:
#   RSpec.describe "MyFeature", :platform_test_fonts do
#     it "installs the test font" do
#       font_paths = Fontist::Font.install(test_font, confirmation: "yes")
#       expect(font_paths).to include(include(test_font_file))
#     end
#   end

RSpec.shared_context "platform test fonts", :platform_test_fonts do
  # Primary installable test font (not pre-installed on current platform)
  let(:test_font) { Fontist::Test::PlatformFonts.installable_test_font }
  let(:test_formula) { Fontist::Test::PlatformFonts.installable_test_formula }
  let(:test_font_file) { Fontist::Test::PlatformFonts.installable_test_font_file }
  let(:test_font_full) { Fontist::Test::PlatformFonts.installable_test_font_full_name }
  let(:test_font_downcase) { test_font.downcase }

  # Secondary installable test font (for multi-font tests)
  let(:test_font2) { Fontist::Test::PlatformFonts.second_installable_test_font }
  let(:test_formula2) { Fontist::Test::PlatformFonts.second_installable_test_formula }
  let(:test_font_file2) { Fontist::Test::PlatformFonts.second_installable_test_font_file }
  let(:test_font_full2) { Fontist::Test::PlatformFonts.second_installable_test_font_full_name }
  let(:test_font2_downcase) { test_font2.downcase }

  # Formula key (filename without .yml extension)
  let(:test_formula_key) { test_formula.sub(".yml", "") }
  let(:test_formula_key2) { test_formula2.sub(".yml", "") }

  before do
    # Ensure the test formulas are loaded
    example_formula(test_formula) if defined?(example_formula)
  end
end

# Shared context for tests that use Andale Mono (legacy)
# This context maintains backward compatibility while using platform-specific fonts
RSpec.shared_context "andale mono context" do
  let(:andale_font) { Fontist::Test::PlatformFonts.installable_test_font }
  let(:andale_formula) { Fontist::Test::PlatformFonts.installable_test_formula }
  let(:andale_font_file) { Fontist::Test::PlatformFonts.installable_test_font_file }
  let(:andale_font_full) { Fontist::Test::PlatformFonts.installable_test_font_full_name }

  before do
    example_formula(andale_formula) if defined?(example_formula)
  end
end
