require "dry-types"
require "recursive-open-struct"
require "active_support/concern"
require "active_support/core_ext/object"
require "active_support/core_ext/module/delegation"

module SmartParams
  extend ActiveSupport::Concern
  include Dry.Types()

  require_relative "smart_params/field"
  require_relative "smart_params/error"
  require_relative "smart_params/version"

  attr_reader :raw
  attr_reader :schema
  attr_reader :fields

  def initialize(raw, safe: true)
    @safe = safe
    @raw = raw
    @schema = self.class.instance_variable_get(:@schema)
    @fields = [@schema, *unfold(raw, @schema.subfields)].sort_by(&:weight)
  rescue SmartParams::Error::InvalidPropertyType => invalid_property_type_exception
    raise invalid_property_type_exception if safe?

    @exception = invalid_property_type_exception
  end

  def payload
    if @exception.present?
      @exception
    else
      RecursiveOpenStruct.new(structure)
    end
  end

  def to_hash(options = nil)
    if @exception.present?
      @exception.as_json(options)
    else
      structure.as_json(options) || {}
    end
  end
  alias_method :as_json, :to_hash

  delegate :[], to: :to_hash
  delegate :fetch, to: :to_hash
  delegate :fetch_values, to: :to_hash
  delegate :merge, to: :to_hash
  delegate :keys, to: :to_hash
  delegate :key?, to: :to_hash
  delegate :has_key?, to: :to_hash
  delegate :values, to: :to_hash
  delegate :value?, to: :to_hash
  delegate :has_value?, to: :to_hash
  delegate :dig, to: :to_hash
  delegate :to_s, to: :to_hash

  def method_missing(name, *arguments, &block)
    if payload.respond_to?(name)
      payload.public_send(name)
    else
      super
    end
  end

  # This function basically takes a list of fields and reduces them into a tree of values
  private def structure
    fields
      .reject(&:removable?)
      .map(&:to_hash)
      .reduce(&:deep_merge)
  end

  # This funcion takes a nested field tree and turns it into a list of fields
  private def unfold(raw, subfields)
    subfields.to_a.reduce([]) do |list, field|
      field.claim(raw)

      if field.deep?
        [*list, field, *unfold(raw, field.subfields)]
      else
        [*list, field]
      end
    end.flatten
  end

  private def safe?
    @safe
  end

  class_methods do
    def schema(type:, &subfield)
      @schema = Field.new(keychain: [], type: type, &subfield)
    end
  end
end
