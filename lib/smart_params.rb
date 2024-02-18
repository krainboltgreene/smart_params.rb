# frozen_string_literal: true

require "dry-types"
require "active_support/concern"
require "active_support/core_ext/object"
require "active_support/core_ext/module"

module SmartParams
  require_relative "smart_params/invalid_payload_exception"
  require_relative "smart_params/invalid_property_type_exception"
  require_relative "smart_params/missing_property_exception"
  require_relative "smart_params/namespace_already_defined_exception"
  require_relative "smart_params/no_matching_namespace_exception"
  require_relative "smart_params/field"
  require_relative "smart_params/fluent_language"

  def self.validate!(schema, raw, namespace = :default)
    case map(fetch_namespace(schema, namespace), raw)
    in [result, []]
      result
    in [_, failures]
      raise InvalidPayloadException.new(failures:)
    end
  end

  def self.from(schema, raw, namespace = :default)
    case map(fetch_namespace(schema, namespace), raw)
    in [result, []]
      result
    in [_, failures]
      failures
    end
  end

  private_class_method def self.map(fields, raw)
    fields.reduce([Hash.new { |h, k| h[k] = h.class.new(&h.default_proc) }, []]) do |(result, failures), field|
      case field.map(raw)
      in :skip
        [result, failures]
      in [:ok, value]
        [field.update_in(result, value), failures]
      in Dry::Types::Result::Success => success
        [field.update_in(result, success.input), failures]
      in Dry::Types::Result::Failure => failure
        [result, [*failures, InvalidPropertyTypeException.new(path: field.path, wanted: field.type, raw: failure.input, grievance: failure.error)]]
      in [:error, value]
        [result, [*failures, value]]
      end
    end
  end

  private_class_method def self.fetch_namespace(schema, namespace)
    schema.namespaces[namespace] || raise(NoMatchingNamespaceException.new(namespace:, available: schema.namespaces.keys))
  end
end
