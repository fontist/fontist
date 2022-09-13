RSpec::Matchers.define :include_yaml do |expected|
  match do |actual|
    @actual = YAML.safe_load(actual)
    values_match? expected, @actual
  rescue Psych::SyntaxError
    false
  end
end
