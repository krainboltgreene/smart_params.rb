module SmartParams
  class NamespaceAlreadyDefinedException < StandardError
    def initialize(namespace:)
      @namespace = namespace
      super(message)
    end

    def message
      "#{@namespace} was already taken as a schema namespace"
    end
  end
end
