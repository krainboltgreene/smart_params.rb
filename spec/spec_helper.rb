# frozen_string_literal: true

require "pry"
require "smart_params"
require "securerandom"

module AccountSchema
  include SmartParams::FluentLanguage

  schema(:create) do |create|
    field create, :data do |data|
      field data, :id, Coercible::String.optional
      field data, :type, Strict::String
      field data, :attributes do |attributes|
        field attributes, :email, Strict::String
        field attributes, :username, Strict::String.optional
        field attributes, "full-name", Strict::String.optional
        field(attributes, :password, Strict::String.default { SecureRandom.hex(32) }.optional)
      end
    end
    field create, :meta, Strict::Hash.optional
    field create, :included, Strict::Array.optional
  end

  schema(:index) do |index|
    field index, :meta, Strict::Hash.optional
    field index, :included, Strict::Array.optional
  end
end

module NullableSchema
  include SmartParams::FluentLanguage

  schema do |root|
    field root, :data, optional: true do |data|
      field data, :id, Coercible::String.optional
      field data, :type, Strict::String.optional
    end
  end
end

module NullableRequiredSubfieldSchema
  include SmartParams::FluentLanguage

  schema do |root|
    field root, :data, optional: true do |data|
      field data, :id, Coercible::String
      field data, :type, Strict::String.optional
    end
  end
end

RSpec.configure do |let|
  # Enable flags like --only-failures and --next-failure
  let.example_status_persistence_file_path = "tmp/.rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  let.disable_monkey_patching!

  # Exit the spec after the first failure
  # let.fail_fast = true

  # Only run a specific file, using the ENV variable
  # Example: FILE=lib/strong_params/version_spec.rb bundle exec rake
  let.pattern = ENV.fetch("FILE", nil)

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
