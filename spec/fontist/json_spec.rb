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

    { "[" => "]", '{"a":' => "}" }.each do |opening, closing|
      it "accepts #{opening} nesting at the yeptris depth boundary" do
        scalar_source = "#{opening * 999}0#{closing * 999}"
        empty_source = "#{opening * 999}[]#{closing * 999}"
        path = Array.new(999, opening == "[" ? 0 : "a")

        expect(json.parse(scalar_source).dig(*path)).to eq(0)
        expect(json.parse(empty_source).dig(*path)).to eq([])
      end

      it "rejects #{opening} nesting beyond the yeptris depth boundary" do
        scalar_source = "#{opening * 1000}0#{closing * 1000}"
        empty_source = "#{opening * 1000}[]#{closing * 1000}"

        expect { json.parse(scalar_source) }.to raise_error(json::ParseError)
        expect { json.parse(empty_source) }.to raise_error(json::ParseError)
        expect { json.parse(("[" * 5000) + ("]" * 5000)) }
          .to raise_error(json::ParseError)
      end
    end

    it "rejects duplicate keys containing overly nested values" do
      nested = "#{'[' * 999}0#{']' * 999}"

      expect { json.parse(%({"a":#{nested},"a":0})) }
        .to raise_error(json::ParseError)
    end

    it "rejects duplicate keys within the nesting limit" do
      expect { json.parse('{"a":1,"a":2}') }.to raise_error(json::ParseError)
    end

    it "ignores brackets and escaped quotes inside strings" do
      value = "[\"#{'[' * 1000}\\]"

      expect(json.parse(json.dump(value))).to eq(value)
    end
  end

  shared_examples "compatible JSON dumping" do
    it "serializes Date and DateTime values as ISO 8601 strings" do
      values = [Date.new(2024, 1, 2), DateTime.new(2024, 1, 2)]
      expected = ["2024-01-02", "2024-01-02T00:00:00+00:00"]

      expect(json.parse(json.dump(values))).to eq(expected)
      expect(json.parse(json.pretty(values))).to eq(expected)
    end

    it "serializes Time values with their offset and whole seconds" do
      value = Time.at(0, 123_456).getlocal("+05:00")
      timestamp = "1970-01-01T05:00:00+05:00"

      expect(json.dump(value)).to eq(%("#{timestamp}"))
      expect(json.pretty(value)).to eq(%("#{timestamp}"))
      expect(json.parse(json.dump({ "time" => [value] })))
        .to eq({ "time" => [timestamp] })
      expect(json.parse(json.pretty({ "time" => [value] })))
        .to eq({ "time" => [timestamp] })
    end

    ["\xff", "\xff".b].each do |value|
      it "preserves invalid UTF-8 bytes in #{value.encoding} strings" do
        expect(json.dump(value).bytes).to eq([34, 255, 34])
        expect(json.pretty(value).bytes).to eq([34, 255, 34])
        expect(json.dump({ "value" => [value] }).b)
          .to eq("{\"value\":[\"\xff\"]}".b)
        expect(json.pretty([value]).b).to eq("[\n  \"\xff\"\n]".b)
      end
    end

    it "preserves UTF-8 text and JSON escapes alongside invalid bytes" do
      value = "café\n\t\"\\\x00\xff"

      expect(json.dump(value).b).to eq("\"café\\n\\t\\\"\\\\\\u0000\xff\"".b)
    end

    it "preserves invalid bytes in keys without merging stringified keys" do
      value = { "\xff" => "café", :a => 1, "a" => 2 }

      expect(json.dump(value).b).to eq("{\"\xff\":\"café\",\"a\":1,\"a\":2}".b)
    end

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
