# frozen_string_literal: true

module SmartParams
  class InvalidPropertyTypeException
    attr_reader :path
    attr_reader :wanted
    attr_reader :raw
    attr_reader :type

    def initialize(path:, wanted:, raw:)
      @path = path
      @wanted = wanted
      @raw = raw
      @type = raw.inspect
    end

    def message
      "expected /#{path.join('/')} to be #{wanted}, but is #{type}"
    end

    def as_json
      {
        "path" => path,
        "wanted" => wanted,
        "raw" => raw
      }
    end
  end
end
