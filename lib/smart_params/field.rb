module SmartParams
  class Field
    attr_reader :keychain
    attr_reader :subfields
    attr_reader :type

    def initialize(keychain:, type:, nullable: false, &nesting)
      @keychain = Array(keychain)
      @subfields = Set.new
      @type = type
      @nullable = nullable
      # Is the value exactly null?
      @null = false
      # Value of the field. Not set unless field is a leaf (no children)
      @value = nil
      @specified = false
      @dirty = false

      if block_given?
        instance_eval(&nesting)
      end
    end

    def deep?
      return false if nullable? && !!@null
      subfields.present?
    end

    def root?
      keychain.size == 0
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
      return true if empty? || subfields.select { |sub| !sub.empty? }.any?
      false
    end

    # Check if we should consider this value even when empty.
    def allow_empty?
      return true if specified? && nullable?
      return subfields.select(&:allow_empty?).any?
      false
    end

    def claim(raw)
      v = dug(raw)

      if v.nil?
        @null = true
      end

      return type[v] if deep?

      @value = type[v]
    rescue Dry::Types::ConstraintError => bad_type_exception
      raise SmartParams::Error::InvalidPropertyType, keychain: keychain, wanted: type, raw: if keychain.empty? then raw else raw.dig(*keychain) end
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
      !@specified && empty? && !allow_empty?
    end

    def weight
      keychain.map(&:to_s)
    end

    private def field(key, type:, nullable: false, &subfield)
      if nullable
        type |= SmartParams::Strict::Nil
      end
      @subfields << self.class.new(keychain: [*keychain, key], type: type, nullable: nullable, &subfield)
    end

    # Very busy method with recent changes. TODO: clean-up
    private def dug(raw)
      return raw if keychain.empty?

      # If value provided is a hash, check if it's dirty. See #dirty? for
      # more info.
      if nullable?
        hash = raw.dig(*keychain)
        if hash.respond_to?(:keys)
          others =  hash.keys - [keychain.last]
          @dirty = others.any?
        end
      end

      # Trace the keychain to find out if the field is explicitly set in the
      # input hash.
      at = raw
      exact = true
      keychain.each { |key|
        if at.respond_to?(:key?) && at.key?(key)
          at = at[key]
        else
          exact = false
          break
        end
      }
      @specified = exact

      raw.dig(*keychain)
    end
  end
end
