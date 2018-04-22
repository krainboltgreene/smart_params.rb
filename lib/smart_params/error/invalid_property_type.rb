module SmartParams
  class Error
    class InvalidPropertyType < Error
      attr_reader :keychain
      attr_reader :wanted
      attr_reader :raw

      def initialize(keychain:, wanted:, raw:)
        @keychain = keychain
        @wanted = type
        @raw = raw
      end

      def message
        "expected #{keychain.inspect} to be wanted of #{wanted.type.name}, but was #{raw.inspect}"
      end

      def as_json
        {
          "keychain" => keychain,
          "wanted" => wanted.type.name,
          "raw" => raw
        }
      end
    end
  end
end