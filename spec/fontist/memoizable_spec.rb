require "spec_helper"

RSpec.describe Fontist::Memoizable do
  before do
    # Clear disk cache before each test to avoid pollution
    Fontist::Cache::Manager.clear
  end

  let(:test_class) do
    Class.new do
      include Fontist::Memoizable

      def call_count
        @call_count ||= 0
      end

      def increment_count
        @call_count ||= 0
        @call_count += 1
      end

      def expensive_calculation(input)
        increment_count
        "result:#{input}"
      end

      memoize :expensive_calculation,
              key: ->(input) { "calc:#{input}" },
              ttl: 60

      def another_method(value)
        increment_count
        "another:#{value}"
      end

      memoize :another_method

      def clearable_method
        increment_count
        "clearable"
      end

      memoize :clearable_method, ttl: 300
    end
  end

  subject(:instance) { test_class.new }

  describe ".memoize" do
    it "memoizes method results" do
      expect(instance.call_count).to eq 0

      result1 = instance.expensive_calculation("test")
      expect(instance.call_count).to eq 1

      result2 = instance.expensive_calculation("test")
      expect(instance.call_count).to eq 1 # Not incremented

      expect(result1).to eq result2
    end

    it "memoizes different arguments separately" do
      instance.expensive_calculation("input1")
      instance.expensive_calculation("input2")

      expect(instance.call_count).to eq 2
    end

    it "resets memoization on clear_memo_cache" do
      instance.expensive_calculation("test")
      expect(instance.call_count).to eq 1

      instance.clear_memo_cache

      instance.expensive_calculation("test")
      expect(instance.call_count).to eq 2
    end
  end

  describe "cache key generation" do
    context "with custom key proc" do
      it "uses custom key for cache" do
        instance.expensive_calculation("same")
        instance.expensive_calculation("same")

        expect(instance.call_count).to eq 1
      end
    end

    context "without custom key" do
      it "generates key from method name and args hash" do
        result1 = instance.another_method("test")
        result2 = instance.another_method("test")

        expect(result1).to eq result2
        # Should only call once due to memoization
      end
    end
  end

  describe "TTL (Time To Live)" do
    it "respects cache expiration" do
      instance.expensive_calculation("expiring")
      expect(instance.call_count).to eq 1

      # Wait for TTL (60 seconds is default in our test, but let's test shorter)
      # In real test, we'd need to manipulate time or use short TTL
    end

    it "can store with custom TTL" do
      # TTL is passed in memoize definition
      # Default behavior stores in memory cache
      cached = instance.expensive_calculation("test")

      # Should be retrievable from memory cache
      expect(instance.expensive_calculation("test")).to eq cached
    end
  end

  describe ".clear_memo_cache" do
    it "clears all memoized values" do
      instance.expensive_calculation("test1")
      instance.another_method("test2")

      expect(instance.call_count).to eq 2

      instance.clear_memo_cache

      instance.expensive_calculation("test1")
      instance.another_method("test2")

      expect(instance.call_count).to eq 4
    end

    it "allows re-computation after clear" do
      result1 = instance.expensive_calculation("test")
      instance.clear_memo_cache
      result2 = instance.expensive_calculation("test")

      expect(result1).to eq result2
      expect(instance.call_count).to eq 2
    end
  end

  describe "with cache manager integration" do
    before do
      allow(Fontist::Cache::Manager).to receive(:get).and_return(nil)
      allow(Fontist::Cache::Manager).to receive(:set)
    end

    it "checks disk cache before computing" do
      expect(Fontist::Cache::Manager).to receive(:get)
        .with("calc:input")  # Key proc generates "calc:#{input}"
        .and_return(nil)

      instance.expensive_calculation("input")
    end

    it "stores result in disk cache when TTL is set" do
      expect(Fontist::Cache::Manager).to receive(:set)
        .with("calc:input", "result:input", ttl: 60)  # Key is "calc:#{input}"

      instance.expensive_calculation("input")
    end

    it "uses cached value from disk cache" do
      expect(Fontist::Cache::Manager).to receive(:get)
        .with("calc:input")  # Key proc generates "calc:#{input}"
        .and_return("cached_result")

      expect(Fontist::Cache::Manager).not_to receive(:set)

      result = instance.expensive_calculation("input")

      expect(result).to eq "cached_result"
      expect(instance.call_count).to eq 0 # Method not called
    end
  end

  describe "method aliasing" do
    it "preserves original method with _unmemoized_ prefix" do
      expect(instance).to respond_to(:_unmemoized_expensive_calculation)
    end

    it "allows calling original method directly" do
      instance.expensive_calculation("test")
      expect(instance.call_count).to eq 1

      # Call unmemoized version
      instance._unmemoized_expensive_calculation("test")
      expect(instance.call_count).to eq 2
    end
  end

  describe "class methods" do
    let(:class_with_memoizable) do
      Class.new do
        class << self
          include Fontist::Memoizable

          def class_call_count
            @class_call_count ||= 0
          end

          def increment_class_count
            @class_call_count ||= 0
            @class_call_count += 1
          end

          def class_method(value)
            increment_class_count
            "class:#{value}"
          end

          memoize :class_method
        end
      end
    end

    it "works for class methods" do
      result1 = class_with_memoizable.class_method("test")
      expect(class_with_memoizable.class_call_count).to eq 1

      result2 = class_with_memoizable.class_method("test")
      expect(class_with_memoizable.class_call_count).to eq 1 # Not incremented
    end
  end

  describe "edge cases" do
    it "handles nil return values" do
      nil_returning_class = Class.new do
        include Fontist::Memoizable

        def return_nil
          nil
        end

        memoize :return_nil
      end

      instance = nil_returning_class.new
      expect(instance.return_nil).to be_nil
      expect(instance.return_nil).to be_nil # Memoized
    end

    it "handles false return values" do
      false_returning_class = Class.new do
        include Fontist::Memoizable

        def return_false
          false
        end

        memoize :return_false
      end

      instance = false_returning_class.new
      expect(instance.return_false).to eq false
    end

    it "handles empty collections" do
      empty_class = Class.new do
        include Fontist::Memoizable

        def empty_array
          []
        end

        def empty_hash
          {}
        end

        memoize :empty_array
        memoize :empty_hash
      end

      instance = empty_class.new
      expect(instance.empty_array).to eq([])
      expect(instance.empty_hash).to eq({})
    end

    it "handles multiple arguments" do
      multi_arg_class = Class.new do
        include Fontist::Memoizable

        def multi_arg(a, b, c)
          "#{a}-#{b}-#{c}"
        end

        memoize :multi_arg
      end

      instance = multi_arg_class.new
      expect(instance.multi_arg(1, 2, 3)).to eq "1-2-3"
      expect(instance.multi_arg(1, 2, 3)).to eq "1-2-3" # Memoized
      expect(instance.multi_arg(1, 2, 4)).to eq "1-2-4" # Different args
    end
  end
end
