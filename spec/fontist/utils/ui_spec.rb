require "spec_helper"

RSpec.describe Fontist::Utils::UI do
  before do
    allow(Fontist.ui).to receive(:say).and_call_original
    allow(Fontist.ui).to receive(:success).and_call_original
    allow(Fontist.ui).to receive(:error).and_call_original
    allow(Fontist.ui).to receive(:print).and_call_original
  end

  context "by default" do
    around do |example|
      Fontist.ui.level.tap do |level|
        Fontist.ui.level = Fontist.ui.default_level
        example.run
        Fontist.ui.level = level
      end
    end

    it "prints nothing" do
      expect { Fontist.ui.success("msg") }.to output("").to_stdout
      expect { Fontist.ui.error("msg") }.to output("").to_stdout
      expect { Fontist.ui.say("msg") }.to output("").to_stdout
      expect { Fontist.ui.print("msg") }.to output("").to_stdout
      expect { Fontist.ui.debug("msg") }.to output("").to_stdout
    end
  end

  context "warn level" do
    around do |example|
      Fontist.ui.level = :warn
      example.run
      Fontist.ui.level = Fontist.ui.default_level
    end

    it "prints only error" do
      expect { Fontist.ui.success("msg") }.to output("").to_stdout
      expect { Fontist.ui.error("msg") }.to output("msg\n").to_stdout
      expect { Fontist.ui.say("msg") }.to output("").to_stdout
      expect { Fontist.ui.print("msg") }.to output("").to_stdout
      expect { Fontist.ui.debug("msg") }.to output("").to_stdout
    end
  end

  context "info level" do
    around do |example|
      Fontist.ui.level = :info
      example.run
      Fontist.ui.level = Fontist.ui.default_level
    end

    it "prints everything except debug" do
      expect { Fontist.ui.success("msg") }.to output("msg\n").to_stdout
      expect { Fontist.ui.error("msg") }.to output("msg\n").to_stdout
      expect { Fontist.ui.say("msg") }.to output("msg\n").to_stdout
      expect { Fontist.ui.print("msg") }.to output("msg").to_stdout
      expect { Fontist.ui.debug("msg") }.to output("").to_stdout
    end
  end

  context "debug level" do
    around do |example|
      Fontist.ui.level = :debug
      example.run
      Fontist.ui.level = Fontist.ui.default_level
    end

    it "prints everything" do
      expect { Fontist.ui.success("msg") }.to output("msg\n").to_stdout
      expect { Fontist.ui.error("msg") }.to output("msg\n").to_stdout
      expect { Fontist.ui.say("msg") }.to output("msg\n").to_stdout
      expect { Fontist.ui.print("msg") }.to output("msg").to_stdout
      expect { Fontist.ui.debug("msg") }.to output("msg\n").to_stdout
    end
  end
end
