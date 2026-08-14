# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class Base
        def self.convert(rdl_model, root_data, input_data)
          (@conerter ||= new).convert(rdl_model, root_data, input_data)
        end

        def convert(rdl_model, root_data, input_data)
          insert_external(rdl_model, input_data) if external?(rdl_model)
          input_data = insert_design_boundary(rdl_model, root_data) if design_boundary_required?(rdl_model)

          input_data = input_data.child(layer_name)
          convert_rdl_model(rdl_model, root_data, input_data)

          rdl_model.instances.each do |sub_model|
            converter = select_converter(sub_model)
            converter.convert(sub_model, root_data, input_data)
          end
        end

        private

        def external?(_rdl_model)
          false
        end

        def design_boundary_required?(_rdl_model)
          false
        end

        def select_converter(rdl_model)
          {
            addrmap: AddrMap,
            regfile: RegFile,
            reg: Reg,
            field: Field,
            mem: Mem
          }[rdl_model.layer]
        end

        def to_input_value(rdl_model, property_name)
          value = rdl_model.property(property_name)
          position = value.token_range&.head&.position
          Core::InputBase::InputValue.new(value.value, position)
        end
      end
    end
  end
end
