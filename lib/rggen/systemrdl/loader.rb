# frozen_string_literal: true

module RgGen
  module SystemRDL
    class Loader < Core::RegisterMap::Loader
      support_types [:rdl]

      private

      def read_file(file)
        ::SystemRDL.compile(file)
      end

      def format_data(rdl_models, input_data, _layer, _file)
        rdl_models.each do |rdl_model|
          Converter::AddrMap.convert(rdl_model, input_data, input_data)
        end
      end
    end
  end
end
