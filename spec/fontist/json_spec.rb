require "spec_helper"

RSpec.describe Fontist::JSON do
  it "round-trips and preserves error classes when yeptris is unavailable" do
    sandbox = Module.new
    allow(sandbox).to receive(:require).and_call_original
    allow(sandbox).to receive(:require).with("yeptris")
      .and_raise(LoadError, "cannot load such file -- yeptris")
    hide_const("Yeptris")
    path = File.expand_path("../../lib/fontist/json.rb", __dir__)

    sandbox.module_eval(File.read(path), path)
    json = sandbox::Fontist::JSON
    value = { "name" => "Lato", "styles" => ["Regular", nil, true, 12] }

    expect(json.parse(json.dump(value))).to eq(value)
    expect(json.parse(json.pretty(value))).to eq(value)
    expect { json.parse("{not json") }.to raise_error(json::ParseError)
    expect { json.parse(nil) }.to raise_error(json::ParseError)
    expect { json.dump(Object.new) }.to raise_error(json::DumpError)
    expect { json.pretty(Object.new) }.to raise_error(json::DumpError)
  end

  describe ".parse and .dump" do
    it "round-trips plain Ruby structures with string keys" do
      value = { "a" => 1, "b" => [1, 2, { "c" => nil }], "d" => "text" }

      expect(described_class.parse(described_class.dump(value))).to eq(value)
    end

    it "parses compact and indented documents" do
      expect(described_class.parse("{\n  \"a\": 1\n}\n")).to eq({ "a" => 1 })
    end

    it "raises ParseError for malformed input" do
      expect { described_class.parse("{not json") }
        .to raise_error(Fontist::JSON::ParseError)
    end

    it "raises ParseError for non-string input" do
      expect { described_class.parse(nil) }
        .to raise_error(Fontist::JSON::ParseError)
    end

    it "raises DumpError for values outside the JSON type system" do
      expect { described_class.dump(Object.new) }
        .to raise_error(Fontist::JSON::DumpError)
    end
  end

  describe ".pretty" do
    it "produces two-space-indented output" do
      expected = <<~JSON.delete_suffix("\n")
        {
          "a": [
            1,
            {
              "b": null
            }
          ]
        }
      JSON

      expect(described_class.pretty({ "a" => [1, { "b" => nil }] }))
        .to eq(expected)
    end

    it "prints empty containers compactly" do
      expect(described_class.pretty({ "a" => [], "b" => {} }))
        .to eq("{\n  \"a\": [],\n  \"b\": {}\n}")
    end

    it "round-trips through parse" do
      value = { "name" => "Lato", "styles" => %w[Regular Bold] }

      expect(described_class.parse(described_class.pretty(value))).to eq(value)
    end
  end
end
