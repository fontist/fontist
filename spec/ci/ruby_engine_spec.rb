require "spec_helper"
require "yaml"
require "open3"

RSpec.describe "Ruby engine CI diagnostics" do
  it "logs the tier that actually served a scan" do
    path = Fontist.root_path.join(".github/workflows/rake.yml")
    workflow = YAML.load_file(path)
    job = workflow.fetch("jobs").fetch("ruby-engine-test")
    step = job.fetch("steps").find do |entry|
      entry["name"] == "Verify and report the selected engine"
    end

    expect(step).not_to be_nil
    expect(step.fetch("shell")).to eq("bundle exec ruby {0}")

    output, error, status = Open3.capture3(
      job.fetch("env"), Gem.ruby, "-rbundler/setup", "-e", step.fetch("run"),
      chdir: Fontist.root_path.to_s
    )

    expect(status.success?).to be(true), error
    expect(output).to include("Fontisan scan served by: ruby")
  end
end
