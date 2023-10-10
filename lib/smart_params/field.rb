# frozen_string_literal: true

module SmartParams
  class Field
    attr_reader :keychain
    attr_reader :subfields
    attr_reader :type
    attr_reader :nullable
    attr_reader :key

    def inspect
      "#<#{self.class.name}:#{__id__} #{[
        ('subschema' if @subschema),
        ("#/#{@keychain.join('/')}" if @keychain),
        ("-> #{type.name}" if @type),
        ("= #{@value.inspect}" if @value)
      ].compact.join(' ')}>"
    end

    def initialize(keychain:, type:, key: nil, subschema: false, nullable: false, &nesting)
      @key = key
      @keychain = Array(keychain)
      @subfields = Set.new
      @type = type
      @nullable = nullable
      @subschema = subschema
      @specified = false
      @dirty = false

      instance_eval(&nesting) if nesting

      if subschema
        @type = @type.schema(subfields.reduce({}) do |mapping, field|
          mapping.merge("#{field.key}#{'?' if field.nullable}": field.type)
        end).with_key_transform(&:to_sym)
      end
      @type = @type.optional if nullable
    end

    def deep?
      # We check @specified directly because we want to know if ANY
      # subfields have been passed, not just ones that match the schema.
      return false if nullable? && @specified

      subfields.present?
    end

    def root?
      keychain.empty?
    end

    def value
      @value || ({} if root?)
    end

    def nullable?
      !!@nullable
    end

    def specified?
      if nullable?
        !!@specified && clean?
      else
        !!@specified
      end
    end

    # For nullable hashes: Any keys not in the schema make the hash dirty.
    # If a key is found that matches the schema, we can consider the hash
    # clean.
    def dirty?
      !!@dirty
    end

    def clean?
      return false if dirty?
      return true if empty? || subfields.reject(&:empty?).any?

      false
    end

    # Check if we should consider this value even when empty.
    def allow_empty?
      return true if specified? && nullable?

      subfields.any?(&:allow_empty?)
    end

    def claim(raw)
      return type[dug(raw)] if deep?

      @value = type[dug(raw)]
    rescue Dry::Types::ConstraintError => _constraint_exception
      raise SmartParams::Error::InvalidPropertyType.new(keychain:, wanted: type, raw: keychain.empty? ? raw : raw.dig(*keychain))
    rescue Dry::Types::MissingKeyError => missing_key_exception
      raise SmartParams::Error::InvalidPropertyType.new(keychain:, wanted: type, raw: keychain.empty? ? raw : raw.dig(*keychain), missing_key: missing_key_exception.key)
    end

    def to_hash
      keychain.reverse.reduce(value) do |accumulation, key|
        { key => accumulation }
      end
    end

    def empty?
      value.nil?
    end

    # Should this field be removed from resulting hash?
    def removable?
      empty? && !allow_empty?
    end

    def weight
      keychain.map(&:to_s)
    end

    private def field(key, subschema: false, type: SmartParams::Hash, nullable: false, &subfield)
      @subfields << self.class.new(key:, keychain: [*keychain, key], type:, nullable:, subschema:, &subfield)
    end

    private def subschema(key, nullable: false, &subfield)
      field(key, subschema: true, type: SmartParams::Hash, nullable:, &subfield)
    end

    # Very busy method with recent changes. TODO: clean-up
    private def dug(raw)
      return raw if keychain.empty?

      # If value provided is a hash, check if it's dirty. See #dirty? for
      # more info.
      if nullable?
        hash = raw.dig(*keychain)
        if hash.respond_to?(:keys)
          others = hash.keys - [keychain.last]
          @dirty = others.any?
        end
      end

      # Trace the keychain to find out if the field is explicitly set in the
      # input hash.
      at = raw
      exact = true
      keychain.each do |key|
        if at.respond_to?(:key?) && at.key?(key)
          at = at[key]
        else
          exact = false
          break
        end
      end
      @specified = exact

      raw.dig(*keychain)
    end
  end
end
