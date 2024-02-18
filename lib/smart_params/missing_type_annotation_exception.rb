# frozen_string_literal: true

module SmartParams
  class MissingTypeAnnotationException < StandardError
    attr_accessor :path

    def initialize(path:)
      @path = path
      super(message)
    end

    def message
      "/#{@path.join('/')}  was expected to define a type or a block, but did neither"
    end
  end
end
