# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class Base
        def self.convert(rdl_model, root_data, input_data)
          (@converter ||= new).convert(rdl_model, root_data, input_data)
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

        def convert_name(rdl_model, input_data)
          input_data[:name] = to_input_value(rdl_model.name, rdl_model.token_range)
        end

        def convert_comment(rdl_model, input_data)
          input_data[:comment] = from_property(rdl_model, :desc)
        end

        def set_true?(rdl_model, property_name)
          rdl_model.property(property_name).value == true
        end

        def from_property(rdl_model, property_name)
          property = rdl_model.property(property_name)
          return if property.value.nil?

          from_property_value(property)
        end

        def from_property_value(property)
          if property.value?
            to_input_value(property.value, property.token_range)
          else
            to_input_value(property.value.full_name(exclude_addrmap: true), property.token_range)
          end
        end

        def to_input_value(value, token_range)
          position = token_range&.head&.position
          Core::InputBase::InputValue.new(value, position)
        end
      end
    end
  end
end
