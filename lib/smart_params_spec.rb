require "spec_helper"

RSpec.describe SmartParams do
  let(:schema) { CreateAccountSchema.new(params) }
  let(:nullable_schema) { NullableSchema.new(params) }
  let(:nullable_required_subfield_schema) { NullableRequiredSubfieldSchema.new(params) }

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

  describe "default values" do
    subject { SchemaWithDefaults.new({}).to_hash }

    it "returns default values" do
      expect(subject).to match(
        hash_including(
          {
            "password" => "password"
          }
        )
      )
    end
  end

  describe "nullable values" do
    context "set to nil" do
      subject {nullable_schema.to_hash}

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
              "data" => nil
            }
          )
        )
      end
    end

    context "provided matching data" do
      subject {nullable_schema.to_hash}

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
              "data" => hash_including(
                {
                  "id" => "1",
                  "type" => "people"
                }
              )
            }
          )
        )
      end
    end

    context "not provided" do
      subject {nullable_schema.to_hash}

      let(:params) do
        {
        }
      end

      it "does not set nil relationship" do
        expect(
          subject
        ).to match(
          hash_excluding(
            {
              "data" => nil
            }
          )
        )
      end
    end

    context "with non matching subfield data" do
      subject {nullable_schema.to_hash}

      let(:params) do
        {
          data: {
            is: "garbage"
          }
        }
      end

      it "does not provide data" do
        expect(
          subject
        ).to match(
          hash_excluding(
            {
              "data" => nil
            }
          )
        )
      end
    end

    context "specified with unclean data" do
      subject {nullable_required_subfield_schema.to_hash}

      let(:params) do
        {
          # This will raise an exception becase the data hash is specified
          # but its required subfields are not.
          data: {
            id: "1",
            type: "folders",
            relationships: {
              folder: {
                is: "garbage"
              }
            }
          }
        }
      end

      it "checks subfields" do
        expect {
          subject
        }.to raise_exception(SmartParams::Error::InvalidPropertyType)
      end
    end

    context "specified as null" do
      subject {nullable_required_subfield_schema.to_hash}

      let(:params) do
        {
          # This will not raise an error, since data is allowed to be null.
          # Subfields will not be checked.
          data: {
            id: "1",
            type: "folders",
            relationships: {
              folder: nil
            }
          }
        }
      end

      it "does not check subfields" do
        expect {
          subject
        }.not_to raise_exception
      end

      it "provides clean hash" do
        expect(
          subject
        ).to match(
          hash_including(
            {
              "data" => {
                "id" => "1",
                "type" => "folders",
                "relationships" => {
                  "folder" => nil
                }
              }
            }
          )
        )
      end
    end

    context "unspecified with required subfield" do
      subject {nullable_required_subfield_schema.to_hash}

      let(:params) do
        {
          # In this case, the nullable data hash is not specified so we
          # don't need to enforce constraints on subfields.
          data: {
            id: "1",
            type: "folders"
          }
        }
      end

      it "allows null value" do
        expect {
          subject
        }.not_to raise_exception
      end

      it "provides clean hash" do
        expect(
          subject
        ).to match(
          hash_including(
            {
              "data" => {
                "id" => "1",
                "type" => "folders"
              }
            }
          )
        )
      end
    end

    context "unspecified with specified parent" do
      subject {nullable_required_subfield_schema.to_hash}

      let(:params) do
        {
          data: {
            id: "1",
            type: "folders",
            relationships: {}
          }
        }
      end

      it "allows null value" do
        expect {
          subject
        }.not_to raise_exception
      end

      it "provides clean hash" do
        expect(
          subject
        ).to match(
          hash_including(
            {
              "data" => {
                "id" => "1",
                "type" => "folders",
                "relationships" => {}
              }
            }
          )
        )
      end
    end
  end
end
