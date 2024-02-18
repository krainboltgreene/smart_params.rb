module SmartParams
  class InvalidPayloadException < StandardError
    def initialize(failures:)
      @failures = failures
      super()
    end

    def message
      "structure failed to validate: \n\t#{@failures.map(&:message).join("\n\t")}"
    end
  end
end
