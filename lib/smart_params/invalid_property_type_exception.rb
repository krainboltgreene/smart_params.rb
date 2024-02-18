# frozen_string_literal: true

module SmartParams
  class InvalidPropertyTypeException < StandardError
    attr_reader :path
    attr_reader :wanted
    attr_reader :raw
    attr_reader :type
    attr_reader :grievance

    def initialize(path:, wanted:, raw:, grievance:)
      @path = path
      @wanted = wanted
      @raw = raw
      @type = raw.inspect
      @grievance = grievance
      super(message)
    end

    def message
      "expected /#{path.join('/')} to be #{wanted.name}, but is #{type} and #{grievance}"
    end

    def as_json
      {
        "path" => path,
        "wanted" => wanted,
        "grievance" => grievance,
        "raw" => raw
      }
    end
  end
end
