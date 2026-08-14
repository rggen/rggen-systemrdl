# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class AddrMap < Base
        private

        def external?(rdl_model)
          !rdl_model.parent.nil?
        end

        def layer_name
          :register_block
        end

        def convert_rdl_model(_rdl_model, _root_data, _input_data)
        end
      end
    end
  end
end
