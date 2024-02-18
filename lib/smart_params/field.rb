# frozen_string_literal: true

module SmartParams
  class Field
    attr_reader :path
    attr_reader :type

    def initialize(path:, type:, optional: false, **)
      @path = path
      @type = type
      @optional = !!optional
    end

    def map(raw)
      case [*dig_until(@path, raw), @type, @type&.optional? || @optional]
      in [:error, last, _, false]
        [:error, SmartParams::MissingPropertyException.new(path:, last:)]
      in [:error, _, _, true]
        :skip
      in [:ok, value, nil, _]
        [:ok, value]
      in [:ok, value, type, _]
        type.try(value)
      end
    rescue Dry::Types::ConstraintError => constraint_error
      Dry::Types::Result::Failure.new(value, constraint_error)
    end

    def update_in(result, value)
      *body, butt = @path

      body.reduce(result) do |mapping, key|
        mapping[key]
      end.store(butt, value)

      result
    end

    private def dig_until(keychain, raw)
      keychain.reduce([:ok, raw]) do |result, key|
        case result
        in [:ok, current]
          if current.respond_to?(:key?) && current.key?(key)
            [:ok, current[key]]
          else
            [:error, current]
          end
        in [:error, exception]
          [:error, exception]
        end
      end
    end
  end
end
