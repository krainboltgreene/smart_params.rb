# frozen_string_literal: true

module SmartParams
  class Error
    class InvalidPropertyType < Error
      attr_reader :keychain
      attr_reader :wanted
      attr_reader :raw
      attr_reader :missing_key

      def initialize(keychain:, wanted:, raw:, missing_key: nil)
        super
        @keychain = keychain
        @wanted = wanted
        @raw = raw
        @missing_key = missing_key
      end

      def message
        if missing_key
          "expected #{keychain.inspect} to be #{wanted.name} with key #{missing_key.inspect}, but is #{raw.inspect}"
        else
          "expected #{keychain.inspect} to be #{wanted.name}, but is #{raw.inspect}"
        end
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
