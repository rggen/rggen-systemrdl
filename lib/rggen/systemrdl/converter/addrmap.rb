# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class AddrMap < Base
        private

        def support_external?
          true
        end

        def external?(rdl_model)
          !rdl_model.parent.nil?
        end

        def insert_to_root?
          true
        end

        def layer_name
          :register_block
        end

        def unsupported_properties
          [:sharedextbus, :bigendian, :littleendian, :rsvdset, :rsvdsetX, :msb0]
        end

        def convert_rdl_model(rdl_model, _root_data, input_data)
          convert_addrmap_name(rdl_model, input_data)
          convert_comment(rdl_model, input_data)
          convert_byte_size(rdl_model, input_data)
        end

        def convert_addrmap_name(rdl_model, input_data)
          check_name(rdl_model)

          name = rdl_model.full_name
          escaped_name = escape_name(name.gsub('.', '__'))
          input_data[:name] = to_input_value(escaped_name, rdl_model.token_range)
        end

        def convert_byte_size(rdl_model, input_data)
          input_data[:byte_size] = from_property(rdl_model, :size)
        end
      end
    end
  end
end
