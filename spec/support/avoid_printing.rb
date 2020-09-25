RSpec.configure do |config|
  config.before do
    allow(Fontist.ui).to receive(:say)
    allow(Fontist.ui).to receive(:success)
    allow(Fontist.ui).to receive(:error)
  end
end
