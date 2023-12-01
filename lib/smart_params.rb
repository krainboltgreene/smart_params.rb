# frozen_string_literal: true

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

  def initialize(raw, safe: true, name: :default)
    @safe = safe
    @raw = raw
    @schema = self.class.instance_variable_get(:@schema)[name]

    @fields = [@schema, *unfold(@schema.subfields)].sort_by(&:weight).each { |field| field.claim(raw) }
    binding.pry
  rescue SmartParams::Error::InvalidPropertyType => invalid_property_exception
    raise invalid_property_exception if safe?

    @exception = invalid_property_exception
  end

  def errors
    fields.flat_map(&:errors).compact
  end

  def inspect
    "#<#{self.class.name}:#{__id__} @fields=#{@fields.inspect} @raw=#{@raw.inspect}>"
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
  alias as_json to_hash

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

  def respond_to_missing?(name, include_private = false)
    payload.respond_to?(name) || super
  end

  def method_missing(name, *arguments, &)
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
  private def unfold(subfields)
    subfields.to_a.reduce([]) do |list, field|
      if field.deep?
        [*list, field, *unfold(field.subfields.to_a)]
      else
        [*list, field]
      end
    end.flatten
  end

  private def safe?
    @safe
  end

  class_methods do
    def schema(name: :default, &definitions)
      @schema ||= {}
      @schema[name] = Field.new(keychain: [], type: SmartParams::Hash, subschema: false, &definitions)
    end
  end
end
