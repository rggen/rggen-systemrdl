# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class Reg < Base
        private

        def external?(ral_model)
          ral_model.external
        end

        def layer_name
          :register
        end

        def unsupported_properties
          [:shared]
        end

        def convert_rdl_model(rdl_model, _root_data, input_data)
          convert_name(rdl_model, input_data)
          convert_comment(rdl_model, input_data)
          convert_offset_address(rdl_model, input_data)
        end
      end
    end
  end
end
