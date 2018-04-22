require "spec_helper"

RSpec.describe SmartParams::Error::InvalidPropertyType do
  let(:error) { described_class.new(keychain: [:data], wanted: SmartParams::Strict::Hash, raw: "") }

  describe "#message" do
    subject { error.message }

    it "returns the message" do
      expect(subject).to eq("expected [:data] to be Hash, but was \"\"")
    end
  end
end
