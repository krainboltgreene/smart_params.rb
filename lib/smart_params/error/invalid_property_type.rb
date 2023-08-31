# frozen_string_literal: true

module SmartParams
  class Error
    class InvalidPropertyType < Error
      attr_reader :keychain
      attr_reader :wanted
      attr_reader :raw

      def initialize(keychain:, wanted:, raw:)
        super
        @keychain = keychain
        @wanted = wanted
        @raw = raw
      end

      def message
        "expected #{keychain.inspect} to be #{wanted.name}, but was #{raw.inspect}"
      end

      def as_json
        {
          "keychain" => keychain,
          "wanted" => wanted.name,
          "raw" => raw
        }
      end
    end
  end
end
