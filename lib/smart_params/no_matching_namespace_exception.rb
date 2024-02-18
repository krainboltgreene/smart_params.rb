module SmartParams
  class NoMatchingNamespaceException < StandardError
    def initialize(namespace:, available:)
      @namespace = namespace
      @available = available
      super(message)
    end

    def message
      "#{@namespace} does not exist, only #{@available.inspect}"
    end
  end
end
