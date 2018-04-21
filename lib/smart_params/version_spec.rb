require "spec_helper"

RSpec.describe SmartParams::VERSION do
  it "should be a string" do
    expect(SmartParams::VERSION).to be_kind_of(String)
  end
end
