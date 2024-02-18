# frozen_string_literal: true

module SmartParams
  class MissingPropertyException < StandardError
    attr_accessor :path
    attr_accessor :last

    def initialize(path:, last:)
      @path = path
      @last = last
      super(message)
    end

    def message
      "/#{@path.join('/')} is missing from the structure, last node was #{@last.inspect}"
    end
  end
end
