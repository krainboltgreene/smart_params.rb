require "ostruct"
require "dry-types"
require "recursive-open-struct"
require "active_support/concern"
require "active_support/core_ext/object"

module SmartParams
  extend ActiveSupport::Concern
  include Dry::Types.module

  RECURSIVE_TREE = ->(accumulated, key) {accumulated[key] = Hash.new(&RECURSIVE_TREE)}

  require_relative "smart_params/field"
  require_relative "smart_params/error"
  require_relative "smart_params/version"

  attr_reader :raw
  attr_reader :schema
  attr_reader :fields

  def initialize(raw, safe: true)
    @raw = raw
    @schema = self.class.instance_variable_get(:@schema)
    @fields = [@schema, *unfold(@schema.subfields)]
      .sort_by(&:weight)
      .each { |field| field.claim(raw) }
    @safe = safe
  rescue SmartParams::Error::InvalidPropertyType => invalid_property_type_exception
    if safe?
      raise invalid_property_type_exception
    else
      @exception = invalid_property_type_exception
    end
  end

  def payload
    if @exception.present?
      @exception
    else
      RecursiveOpenStruct.new(structure)
    end
  end

  def as_json
    if @exception.present?
      @exception.as_json
    else
      structure.deep_stringify_keys
    end
  end

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
      .reject(&:empty?)
      .map(&:to_hash)
      .map do |hash|
        # NOTE: okay, so this looks weird, but it's because the root type has no key
        if hash.key?(nil) then hash.fetch(nil) else hash end
      end
      .reduce(&:deep_merge)
  end

  # This funcion takes a nested field tree and turns it into a list of fields
  private def unfold(subfields)
    subfields.to_a.reduce([]) do |list, field|
      if field.deep?
        [*list, field, *unfold(field.subfields)]
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
