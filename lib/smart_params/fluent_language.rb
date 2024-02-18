# frozen_string_literal: true

module SmartParams
  module FluentLanguage
    extend ActiveSupport::Concern

    included do
      include Dry.Types()

      mattr_accessor :namespaces
    end

    class_methods do
      private def schema(namespace = :default)
        self.namespaces ||= {}

        raise SmartParams::NamespaceAlreadyDefinedException.new(namespace:) if self.namespaces.key?(namespace)

        self.namespaces[namespace] = []

        yield(namespace)

        self.namespaces
      end

      private def field(prefix, name, type = nil, **)
        raise MissingTypeException if type.nil? && !block_given?

        root, *remaining = Kernel.Array(prefix)

        path = [root, *remaining, name]

        raise KeyAlreadyDefinedException.new(path:) if self.namespaces[root].any? { |field| field.path == path }

        self.namespaces[root] = [
          *self.namespaces[root],
          SmartParams::Field.new(path: [*remaining, name], type:, subschema: block_given?, **)
        ]

        yield(path) if block_given?

        self.namespaces[root]
      end
    end
  end
end
