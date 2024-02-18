# frozen_string_literal: true

require "spec_helper"

RSpec.describe SmartParams do
  let(:account_payload) { described_class.from(AccountSchema, params, :create) }
  let(:nullable_payload) { described_class.from(NullableSchema, params) }
  let(:nullable_required_subfield_payload) { described_class.from(NullableRequiredSubfieldSchema, params) }

  describe ".validate!(account_payload)" do
    subject { account_payload }

    let(:account_payload) { described_class.validate!(AccountSchema, params, :create) }

    context "with an empty params" do
      let(:params) { {} }

      it "throws an error with a message detailing the invalid property type and given properties" do
        expect { subject }.to raise_exception(SmartParams::InvalidPropertyTypeException, "expected /data to be Key/Value Mapping, but is nil")
      end

      it "throws an error with the missing property and given properties" do
        expect { subject }.to raise_exception do |exception|
          expect(exception).to have_attributes(path: [:data], wanted: a_kind_of(String), raw: nil)
        end
      end
    end

    context "with a good key but bad type" do
      let(:params) { { data: "" } }

      it "throws an error with a message detailing the invalid property, expected type, given type, and given value" do
        expect { subject }.to raise_exception(SmartParams::InvalidPropertyTypeException, "expected /data to be Key/Value Mapping, but is String")
      end

      it "throws an error with the invalid property, expected type, given type, and given value" do
        expect { subject }.to raise_exception do |exception|
          expect(exception).to have_attributes(path: [:data], wanted: a_kind_of(Hash), raw: "")
        end
      end
    end
  end

  describe ".from(account_payload)" do
    subject { account_payload }

    context "with a reasonably good params" do
      let(:params) do
        {
          data: {
            type: "accounts",
            attributes: {
              email: "kurtis@example.com",
              password: "secret"
            }
          },
          meta: {
            jsonapi_version: "1.0"
          },
          included: [
            {
              data: {
                id: "a",
                type: "widget",
                attributes: {
                  title: "Widget A"
                }
              }
            }
          ]
        }
      end

      it "returns as native data types" do
        expect(
          subject
        ).to match(
          hash_including(
            {
              data: hash_including(
                {
                  type: "accounts",
                  attributes: hash_including(
                    {
                      email: "kurtis@example.com",
                      password: an_instance_of(String)
                    }
                  )
                }
              ),
              meta: {
                jsonapi_version: "1.0"
              },
              included: [
                {
                  data: {
                    id: "a",
                    type: "widget",
                    attributes: {
                      title: "Widget A"
                    }
                  }
                }
              ]
            }
          )
        )
      end

      it "has a chain path data.type" do
        expect(subject[:data][:type]).to eq("accounts")
      end

      it "has a chain path data.attributes.email" do
        expect(subject[:data][:attributes][:email]).to eq("kurtis@example.com")
      end

      it "has a chain path data.attributes.password" do
        expect(subject[:data][:attributes][:password]).to be_a(String)
      end

      it "has a chain path meta.jsonapi_version" do
        expect(subject[:meta][:jsonapi_version]).to eq("1.0")
      end
    end

    context "with extra params" do
      let(:params) do
        {
          data: {
            type: "accounts",
            attributes: {
              email: "kurtis@example.com",
              y: "y"
            }
          },
          x: "x"
        }
      end

      it "returns as native data types" do
        expect(
          subject
        ).to match(
          {
            data: hash_including(
              {
                type: "accounts",
                attributes: hash_including(
                  {
                    email: "kurtis@example.com"
                  }
                )
              }
            )
          }
        )
      end
    end

    context "with string key params" do
      let(:params) do
        {
          data: {
            type: "accounts",
            attributes: {
              email: "kurtis@example.com",
              "full-name" => "Kurtis Rainbolt-Greene"
            }
          }
        }
      end

      it "returns as native data types" do
        expect(
          subject
        ).to match(
          {
            data: hash_including(
              {
                type: "accounts",
                attributes: hash_including(
                  {
                    email: "kurtis@example.com",
                    "full-name" => "Kurtis Rainbolt-Greene"
                  }
                )
              }
            )
          }
        )
      end
    end
  end

  describe ".from(nullable_required_subfield_payload)" do
    subject { nullable_required_subfield_payload }

    context "when specified with unclean data" do
      let(:params) do
        {
          # This will raise an exception becase the data hash is specified
          # but its required subfields are not.
          data: {
            is: "garbage"
          }
        }
      end

      it "checks subfields" do
        expect do
          subject
        end.to raise_exception(SmartParams::InvalidPropertyTypeException)
      end
    end

    context "when specified as null" do
      let(:params) do
        {
          # This will not raise an error, since data is allowed to be null.
          # Subfields will not be checked.
          data: nil
        }
      end

      it "checks subfields" do
        expect do
          subject
        end.not_to raise_exception
      end
    end

    context "when unspecified with required subfield" do
      let(:params) do
        {
          # In this case, the nullable data hash is not specified so we
          # don't need to enforce constraints on subfields.
        }
      end

      it "allows null value" do
        expect do
          subject
        end.not_to raise_exception
      end
    end
  end

  describe ".from(nullable_payload)" do
    subject { nullable_payload }

    context "when set to nil" do
      let(:params) do
        {
          data: nil
        }
      end

      it "returns explicit nil" do
        expect(
          subject
        ).to match(
          hash_including(
            {
              data: nil
            }
          )
        )
      end
    end

    context "when provided matching data" do
      let(:params) do
        {
          data: {
            id: "1",
            type: "people"
          }
        }
      end

      it "returns matching data" do
        expect(
          subject
        ).to match(
          hash_including(
            {
              data: hash_including(
                {
                  id: "1",
                  type: "people"
                }
              )
            }
          )
        )
      end
    end

    context "when not provided" do
      let(:params) do
        {}
      end

      it "does not set nil relationship" do
        expect(
          subject
        ).to match(
          hash_excluding(
            {
              data: nil
            }
          )
        )
      end
    end

    context "with non matching subfield data" do
      let(:params) do
        {
          data: {
            id: "x",
            type: "y",
            is: "garbage"
          }
        }
      end

      it "does not return key that isn't specified" do
        expect(
          subject
        ).to match(
          hash_excluding(
            {
              is: "garbage"
            }
          )
        )
      end
    end
  end
end
