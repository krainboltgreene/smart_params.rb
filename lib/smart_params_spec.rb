require "spec_helper"

RSpec.describe SmartParams do
  let(:schema) { CreateAccountSchema.new(params) }

  describe ".new" do
    context "with an empty params" do
      let(:params) { {} }

      it "throws an error with a message detailing the invalid property type and given properties" do
        expect {schema}.to raise_exception(SmartParams::Error::InvalidPropertyType, "expected [:data] to be Hash, but was nil")
      end

      it "throws an error with the missing property and given properties" do
        expect {schema}.to raise_exception do |exception|
          expect(exception).to have_attributes(keychain: [:data], wanted: SmartParams::Strict::Hash, raw: nil)
        end
      end
    end

    context "with a good key but bad type" do
      let(:params) { {data: ""} }

      it "throws an error with a message detailing the invalid property, expected type, given type, and given value" do
        expect { schema }.to raise_exception(SmartParams::Error::InvalidPropertyType, "expected [:data] to be Hash, but was \"\"")
      end

      it "throws an error with the invalid property, expected type, given type, and given value" do
        expect {schema }.to raise_exception do |exception|
          expect(exception).to have_attributes(keychain: [:data], wanted: SmartParams::Strict::Hash, raw: "")
        end
      end
    end
  end

  describe "#payload" do
    context "with a reasonably good params" do
      let(:params) do
        {
          data: {
            type: "accounts",
            attributes: {
              email: "kurtis@example.com"
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
                  title: "Widget A",
                }
              }
            }
          ]
        }
      end

      it "returns the type" do
        expect(schema.payload.data.type).to eq("accounts")
      end

      it "returns the email" do
        expect(schema.data.attributes.email).to eq("kurtis@example.com")
      end

      it "returns the password" do
        expect(schema.data.attributes.password).to be_kind_of(String)
      end

      it "returns the jsonapi version" do
        expect(schema.meta.jsonapi_version).to eq("1.0")
      end
    end
  end

  describe "#as_json" do
    subject {schema.as_json}

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

      it "returns as json" do
        expect(
          subject
        ).to eq(
          {
            "data" => hash_including(
              {
                "type" => "accounts",
                "attributes" => hash_including(
                  {
                    "email" => "kurtis@example.com",
                  }
                )
              }
            ),
          }
        )
      end
    end

    context "with a reasonably good params" do
      let(:params) do
        {
          data: {
            type: "accounts",
            attributes: {
              email: "kurtis@example.com"
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
                  title: "Widget A",
                }
              }
            }
          ]
        }
      end

      it "returns as json" do
        expect(
          subject
        ).to eq(
          hash_including(
            {
              "data" => hash_including(
                {
                  "type" => "accounts",
                  "attributes" => hash_including(
                    {
                      "email" => "kurtis@example.com",
                      "password" => an_instance_of(String)
                    }
                  )
                }
              ),
              "meta" => {
                "jsonapi_version" => "1.0"
              },
              "included" => [
                {
                  "data" => {
                    "id" => "a",
                    "type" => "widget",
                    "attributes" => {
                      "title" => "Widget A"
                    }
                  }
                }
              ]
            }
          )
        )
      end
    end
  end
end
