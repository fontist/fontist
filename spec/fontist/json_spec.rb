require "spec_helper"

RSpec.describe Fontist::JSON do
  shared_examples "deeply nested JSON" do
    let(:nested_value) { 150.times.reduce([]) { |value, _level| [value] } }
    let(:nested_source) { ("[" * 151) + ("]" * 151) }

    it "parses documents nested beyond 100 levels" do
      expect(json.parse(nested_source)).to eq(nested_value)
    end

    it "dumps values nested beyond 100 levels" do
      expect(json.dump(nested_value)).to eq(nested_source)
    end
  end

  shared_examples "compatible JSON dumping" do
    it "serializes nested Symbol values as strings" do
      expect(json.dump({ "a" => [:b] })).to eq('{"a":["b"]}')
    end

    it "preserves cached hashes containing Symbol values" do
      stub_const("Fontist::JSON", json)

      Dir.mktmpdir do |dir|
        store = Fontist::Cache::Store.new(dir)
        store.set("k", { "a" => :b })

        expect(store.get("k")).to eq({ "a" => "b" })
      end
    end

    { "NaN" => Float::NAN, "Infinity" => Float::INFINITY,
      "-Infinity" => -Float::INFINITY }.each do |text, value|
      it "serializes #{text} as a quoted string" do
        expect(json.dump({ "a" => [value] })).to eq("{\"a\":[\"#{text}\"]}")
      end
    end

    [Hash, String, Array].each do |type|
      it "rejects anonymous #{type} subclasses with the native error message" do
        value = Class.new(type).new

        expect { json.dump({ "a" => [value] }) }
          .to raise_error(json::DumpError,
                          "can't dump anonymous class #{value.class}")
      end

      it "accepts named #{type} subclasses" do
        type_class = stub_const("JSONSpec#{type}", Class.new(type))

        expect(json.dump(type_class.new)).to eq(json.dump(type.new))
      end
    end

    it "rejects hashes with default procs with the native error message" do
      expect { json.dump({ "a" => Hash.new { nil } }) }
        .to raise_error(json::DumpError, "can't dump hash with default proc")
    end

    it "rejects unsupported objects with the native error message" do
      expect { json.dump(Object.new) }
        .to raise_error(json::DumpError,
                        "cannot dump Object: unsupported object " \
                        "(JSON.generate calls to_json on custom types)")
    end
  end

  context "with the default engine" do
    let(:json) { described_class }

    include_examples "deeply nested JSON"
    include_examples "compatible JSON dumping"
  end

  context "without yeptris" do
    let(:json) do
      sandbox = Module.new
      fontist = sandbox.const_set(:Fontist, Module.new)
      backend = fontist.const_set(:JSON, Module.new)
      allow(backend).to receive(:require).and_call_original
      allow(backend).to receive(:require).with("yeptris")
        .and_raise(LoadError, "cannot load such file -- yeptris")
      path = File.expand_path("../../lib/fontist/json.rb", __dir__)
      sandbox.module_eval(File.read(path), path)
      backend
    end

    before { hide_const("Yeptris") }

    include_examples "deeply nested JSON"
    include_examples "compatible JSON dumping"

    it "rejects circular arrays and hashes with DumpError" do
      array = []
      array << array
      hash = {}
      hash["self"] = hash

      expect { json.dump(array) }.to raise_error(json::DumpError)
      expect { json.dump(hash) }.to raise_error(json::DumpError)
    end

    it "accepts containers shared between separate branches" do
      shared = { "styles" => ["Regular"] }

      expect(json.parse(json.dump([shared, shared]))).to eq([shared, shared])
    end
  end

  %w[yeptris yeptris/json].each do |missing|
    it "round-trips and preserves errors when #{missing} is unavailable" do
      sandbox = Module.new
      fontist = sandbox.const_set(:Fontist, Module.new)
      json = fontist.const_set(:JSON, Module.new)
      allow(json).to receive(:require).and_call_original
      allow(json).to receive(:require).with(missing)
        .and_raise(LoadError, "cannot load such file -- #{missing}")
      hide_const("Yeptris")
      path = File.expand_path("../../lib/fontist/json.rb", __dir__)

      sandbox.module_eval(File.read(path), path)
      value = { "name" => "Lato", "styles" => ["Regular", nil, true, 12] }

      expect(json.parse(json.dump(value))).to eq(value)
      expect(json.parse(json.pretty(value))).to eq(value)
      expect(json.pretty(value)).to include('  "name": "Lato"')
      expect { json.parse("{not json") }.to raise_error(json::ParseError)
      expect { json.parse(nil) }.to raise_error(json::ParseError)
      expect { json.dump(Object.new) }.to raise_error(json::DumpError)
      expect { json.dump({ "nested" => [Object.new] }) }
        .to raise_error(json::DumpError)
      expect(json.dump(Float::NAN)).to eq('"NaN"')
      expect { json.pretty(Object.new) }.to raise_error(json::DumpError)
      expect(json).to have_received(:require).with("yeptris").once
    end
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
