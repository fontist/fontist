RSpec::Matchers.define :include_yaml do |expected|
  match do |actual|
    @actual = YAML.safe_load(actual)
    @actual == expected
    values_match? expected, @actual
  end
end
