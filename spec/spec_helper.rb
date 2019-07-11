require "pry"
require "smart_params"
require "securerandom"

class CreateAccountSchema
  include SmartParams

  schema type: Strict::Hash do
    field :data, type: Strict::Hash do
      field :id, type: Coercible::String.optional
      field :type, type: Strict::String
      field :attributes, type: Strict::Hash.optional do
        field :email, type: Strict::String.optional
        field :username, type: Strict::String.optional
        field "full-name", type: Strict::String.optional
        field :password, type: Strict::String.optional.default { SecureRandom.hex(32) }
      end
    end
    field :meta, type: Strict::Hash.optional
    field :included, type: Strict::Array.optional
  end
end

class NullableSchema
  include SmartParams

  schema type: Strict::Hash do
    field :data, type: Strict::Hash | Strict::Nil, nullable: true do
      field :id, type: Coercible::String.optional
      field :type, type: Strict::String.optional
    end
  end
end

class NullableRequiredSubfieldSchema
  include SmartParams

  schema type: Strict::Hash do
    field :data, type: Strict::Hash do
      field :id, type: Strict::String
      field :type, type: Strict::String.enum('folders')
      field :attributes, type: Strict::Hash.optional do
        field :name, type: Strict::String.optional
      end
      field :relationships, type: Strict::Hash.optional do
        field :folder, type: Strict::Hash, nullable: true do
          field :data, type: Strict::Hash do
            field :id, type: Strict::String
            field :type, type: Strict::String.enum('folders')
          end
        end
      end
    end
  end
end

RSpec.configure do |let|
  # Enable flags like --only-failures and --next-failure
  let.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  let.disable_monkey_patching!

  # Exit the spec after the first failure
  # let.fail_fast = true

  # Only run a specific file, using the ENV variable
  # Example: FILE=lib/strong_params/version_spec.rb bundle exec rake
  let.pattern = ENV["FILE"]

  # Show the slowest examples in the suite
  let.profile_examples = true

  # Colorize the output
  let.color = true

  # Output as a document string
  let.default_formatter = "doc"

  let.before(:each, active_record: true) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
  end

  let.before(:each, active_record: true) do
    ActiveRecord::Migration.create_table(:items, force: true) do |table|
      table.integer :subtotal_cents, default: 0, null: false
      table.integer :discount_cents, default: 0, null: false
      table.integer :cart_id, null: false
      table.text :metadata, default: "{}"
      table.timestamps null: false
    end
  end

  let.before(:each, active_record: true) do
    ActiveRecord::Migration.create_table(:carts, force: true) do |table|
      table.integer :discount_cents, default: 0, null: false
      table.string :state, null: false
      table.string :status, null: false, default: :started
      table.integer :consumer_id, null: false
      table.text :metadata, default: "{}"
      table.timestamps null: false
    end
  end

  let.before(:each, active_record: true) do
    ActiveRecord::Migration.create_table(:consumers, force: true) do |table|
      table.string :email, default: 0, null: false
      table.integer :credit_cents, default: 0, null: false
      table.text :metadata, default: "{}"
      table.timestamps null: false
    end
  end

  let.around(:each, active_record: true) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
