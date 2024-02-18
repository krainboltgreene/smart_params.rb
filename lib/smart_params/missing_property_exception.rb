# frozen_string_literal: true

module SmartParams
  class MissingPropertyException < StandardError
    def initialize(path:, last:)
      @path = path
      @last = last
      super()
    end

    def message
      "/#{@path.join('/')} is missing from the structure, last node was #{@last.inspect}"
    end
  end
end
