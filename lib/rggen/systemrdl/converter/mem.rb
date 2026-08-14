# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class Mem
        def convert(rdl_model, _root_data, input_data)
          insert_external(rdl_model, input_data)
        end
      end
    end
  end
end
