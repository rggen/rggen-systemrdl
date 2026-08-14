# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class RegFile < Base
        private

        def external?(rdl_model)
          rdl_model.external
        end

        def layer_name
          :register_file
        end

        def convert_rdl_model(_rdl_model, _root_data, _input_data)
        end
      end
    end
  end
end
