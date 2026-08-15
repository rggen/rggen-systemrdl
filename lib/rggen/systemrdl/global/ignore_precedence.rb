# frozen_string_literal: true

RgGen.define_simple_feature(:global, :ignore_precedence) do
  configuration do
    property :ignore_precedence?, default: false

    input_pattern [{ true => truthy_pattern, false => falsey_pattern }],
                  match_automatically: false

    ignore_empty_value false

    build do |value|
      @ignore_precedence =
        if [true, false].any? { |bool| value == bool }
          value.value
        elsif match_pattern(value)
          match_index
        else
          error "cannot convert #{value.inspect} into boolean"
        end
    end

    printable :ignore_precedence do
      ignore_precedence?
    end
  end
end
