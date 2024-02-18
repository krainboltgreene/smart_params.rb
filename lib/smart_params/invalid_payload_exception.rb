# frozen_string_literal: true

module SmartParams
  class InvalidPayloadException < StandardError
    attr_reader :failures

    def initialize(failures:)
      @failures = failures
      super(message)
    end

    def message
      "structure failed to validate: \n\t#{@failures.map(&:message).join("\n\t")}"
    end
  end
end
