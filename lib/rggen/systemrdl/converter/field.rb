# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class Field < Base
        private

        def layer_name
          :bit_field
        end

        def convert_rdl_model(rdl_model, _root_data, input_data)
          convert_bit_assignment(rdl_model, input_data)
        end

        def convert_bit_assignment(rdl_model, input_data)
          lsb = to_input_value(rdl_model, :lsb)
          width = to_input_value(rdl_model, :width)
          input_data[:bit_assignment] = { lsb:, width: }
        end
      end
    end
  end
end
