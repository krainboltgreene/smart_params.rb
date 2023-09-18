# frozen_string_literal: true

require "spec_helper"

RSpec.describe SmartParams::Error::InvalidPropertyType do
  describe "#message" do
    subject { error.message }

    context "when the error is about the type mismatch" do
      let(:error) { described_class.new(keychain: [:data], wanted: SmartParams::Strict::Hash, raw: "") }

      it "returns the message" do
        expect(subject).to eq("expected [:data] to be Hash, but is \"\"")
      end
    end

    context "when the error is about a missing key" do
      let(:error) { described_class.new(keychain: [:data], wanted: SmartParams::Strict::Hash.schema(data: SmartParams::Strict::String), raw: {}, missing_key: :data) }

      it "returns the message" do
        expect(subject).to eq("expected [:data] to be Hash with key :data, but is {}")
      end
    end
  end
end
