module SmartParams
  class Field
    attr_reader :keychain
    attr_reader :value
    attr_reader :subfields
    attr_reader :type

    def initialize(keychain:, type:, &nesting)
      @keychain = Array(keychain)
      @subfields = Set.new
      @type = type

      if block_given?
        instance_eval(&nesting)
      end
    end

    def deep?
      subfields.present?
    end

    def claim(raw)
      return type[dug(raw)] if deep?

      @value = type[dug(raw)]
    rescue Dry::Types::ConstraintError => bad_type_exception
      raise SmartParams::Error::InvalidPropertyType, keychain: keychain, wanted: type, raw: if keychain.empty? then raw else raw.dig(*keychain) end
    end

    def to_hash
      *chain, key = keychain
      Hash.new(&RECURSIVE_TREE).tap do |tree|
        if chain.any?
          tree.dig(*chain)[key] = value
        else
          tree[key] = value
        end
      end
    end

    def empty?
      value.nil?
    end

    def weight
      keychain
    end

    private def field(key, type:, &subfield)
      @subfields << self.class.new(keychain: [*keychain, key], type: type, &subfield)
    end

    private def dug(raw)
      if keychain.empty?
        raw
      else
        raw.dig(*keychain)
      end
    end
  end
end
