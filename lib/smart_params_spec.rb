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
    subject {schema.payload}

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

      it "has a chain path data.type" do
        expect(subject.data.type).to eq("accounts")
      end

      it "has a chain path data.attributes.email" do
        expect(subject.data.attributes.email).to eq("kurtis@example.com")
      end

      it "has a chain path data.attributes.password" do
        expect(subject.data.attributes.password).to be_kind_of(String)
      end

      it "has a chain path meta.jsonapi_version" do
        expect(subject.meta.jsonapi_version).to eq("1.0")
      end
    end
  end

  shared_examples "native types" do
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
            "data" => hash_including(
              {
                "type" => "accounts",
                "attributes" => hash_including(
                  {
                    "email" => "kurtis@example.com",
                    "full-name" => "Kurtis Rainbolt-Greene"
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

      it "returns as native data types" do
        expect(
          subject
        ).to match(
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

  describe "#to_hash" do
    subject {schema.to_hash}

    include_examples "native types"
  end

  describe "#as_json" do
    subject {schema.as_json}

    include_examples "native types"
  end

  describe "#fetch" do
    subject {schema.fetch("data")}

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

      it "returns the native type" do
        expect(
          subject
        ).to match(
          hash_including(
            {
              "type" => "accounts",
              "attributes" => hash_including(
                {
                  "email" => "kurtis@example.com",
                  "password" => an_instance_of(String)
                }
              )
            }
          )
        )
      end
    end
  end

  describe "#dig" do
    subject {schema.dig("data", "attributes", "email")}

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

      it "returns the native type" do
        expect(
          subject
        ).to eq(
          "kurtis@example.com"
        )
      end
    end
  end

  describe "#fetch_values" do
    subject {schema.fetch_values("data", "meta")}

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

      it "returns the native type" do
        expect(
          subject
        ).to match(
          [
            hash_including(
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
            hash_including(
              {
                "jsonapi_version" => "1.0"
              }
            )
          ]
        )
      end
    end
  end
end
