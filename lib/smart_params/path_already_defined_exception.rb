# frozen_string_literal: true

module SmartParams
  class PathAlreadyDefinedException < StandardError
    def initialize(path:)
      @path = path
      super(message)
    end

    def message
      "/#{@path.join('/')} was already taken as a field path"
    end
  end
end
