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

        def convert_rdl_model(_rdl_model, _root_data, _input_data)
        end
      end
    end
  end
end
