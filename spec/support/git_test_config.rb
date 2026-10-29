# frozen_string_literal: true

# Test-repo git identity setup, portable across the ruby-git 5.x/6.x API
# split: 6.0 removed Repository#config (the setter), config_add is its
# replacement.
module GitTestConfig
  module_function

  def set_test_identity(repo)
    if Gem::Version.new(Git::VERSION) >= Gem::Version.new("6")
      repo.config_add("user.name", "Test")
      repo.config_add("user.email", "test@example.com")
    else
      repo.config("user.name", "Test")
      repo.config("user.email", "test@example.com")
    end
  end
end
