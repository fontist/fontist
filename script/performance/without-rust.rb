# Hosted runners may already have Rust installed. Keep it out of every later
# step so a source gem can only take Fontisan's fail-soft Ruby path.
paths = ENV.fetch("PATH").split(File::PATH_SEPARATOR)
extensions = [""] + ENV.fetch("PATHEXT", "").split(";")
tools = %w[cargo rustc rustup].product(extensions).map(&:join)
paths.reject! do |directory|
  tools.any? { |tool| File.executable?(File.join(directory, tool)) }
end
clean_path = paths.join(File::PATH_SEPARATOR)

%w[ruby bundle].each do |tool|
  available = paths.any? do |directory|
    extensions.any? do |extension|
      File.executable?(File.join(directory, "#{tool}#{extension}"))
    end
  end
  next if available

  warn "ERROR: removing Rust from PATH also removed #{tool}."
  exit 2
end

File.open(ENV.fetch("GITHUB_ENV"), "a") do |output|
  output.puts "PATH=#{clean_path}"
end
puts "Rust excluded from PATH for bundle installation and performance checks."
