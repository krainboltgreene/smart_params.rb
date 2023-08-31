# frozen_string_literal: true

module SmartParams
  class Error < StandardError
    require_relative "error/invalid_property_type"
  end
end
