# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class Base
        def self.convert(rdl_model, root_data, input_data)
          (@converter ||= new).convert(rdl_model, root_data, input_data)
        end

        def convert(rdl_model, root_data, input_data)
          check_external(rdl_model)
          check_unsupported_properties(rdl_model)
          check_property_reference(rdl_model)

          insert_external(rdl_model, input_data) if external?(rdl_model)
          return if region_only?

          input_data = insert_design_boundary(rdl_model, root_data) if design_boundary_required?(rdl_model)
          input_data = input_data.child(layer_name)
          convert_rdl_model(rdl_model, root_data, input_data)

          rdl_model.instances.each do |sub_model|
            converter = select_converter(sub_model)
            converter.convert(sub_model, root_data, input_data)
          end
        end

        private

        def check_external(rdl_model)
          return unless !support_external? && external?(rdl_model)

          error "external #{rdl_model.layer} is not supported", rdl_model.token_range
        end

        def support_external?
          false
        end

        def external?(_rdl_model)
          false
        end

        def insert_external(rdl_model, input_data)
          input_data = input_data.child(:register)
          convert_name(rdl_model, input_data)
          convert_comment(rdl_model, input_data)
          convert_offset_address(rdl_model, input_data)
          convert_external_type(rdl_model, input_data)
        end

        def convert_external_type(rdl_model, input_data)
          size = rdl_model.size
          bus_width = input_data.configuration.bus_width

          if (size % (bus_width / 8)) != 0
            message =
              "#{rdl_model.layer} size is not a multiple of the bus width: " \
              "size #{size} bus width #{bus_width}"
            error message, rdl_model.token_range
          end

          input_data[:type] = to_input_value(:external, nil)
          input_data[:size] = to_input_value(size / (bus_width / 8), nil)
        end

        def check_unsupported_properties(rdl_model)
          unsupported_properties&.each do |property|
            prop = rdl_model.property(property)
            next unless prop.value

            error "#{property} is not supported", prop.token_range
          end
        end

        def unsupported_properties
        end

        def check_property_reference(rdl_model)
          rdl_model.properties.each_value do |prop|
            next unless prop.property_ref?

            error 'property reference is not supported', prop.token_range
          end
        end

        def region_only?
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

        def error(message, token_range)
          pos = token_range&.head&.position
          raise Core::SourceError.new(message, pos)
        end

        def convert_name(rdl_model, input_data)
          name = rdl_model.name
          name.include?('__') &&
            (error "identifier including __ is not allowed: #{name}", rdl_model.token_range)

          input_data[:name] = to_input_value(escape_name(name), rdl_model.token_range)
        end

        def escape_name(name)
          name.gsub('[', '__').gsub(']', '')
        end

        def convert_comment(rdl_model, input_data)
          input_data[:comment] = from_property(rdl_model, :desc)
        end

        def convert_offset_address(rdl_model, input_data)
          input_data[:offset_address] = from_property(rdl_model, :address)
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
