# frozen_string_literal: true

RSpec.describe RgGen::SystemRDL do
  describe 'loading a SystemRDL file' do
    include_context 'configuration common'
    include_context 'systemrdl common'

    it 'loads the SystemRDL file and expands it into a register map' do
      rdl_file = File.join(RGGEN_SYSTEMRDL_ROOT, 'spec', 'fixtures', 'gpio.rdl')

      configuration = create_configuration
      register_map = factory.create(configuration, [rdl_file])

      register_block = register_map.register_blocks[0]
      expect(register_block).to have_property(:name, 'gpio')
      expect(register_block).to have_property(:comment, 'Simple general purpose I/O controller')

      # reg direction
      register = register_block.registers[0]
      expect(register).to have_property(:name, 'direction')
      expect(register).to have_property(:offset_address, 0x00)

      bit_field = register.bit_fields[0]
      expect(bit_field).to have_property(:name, 'dir')
      expect(bit_field).to have_property(:lsb, 0)
      expect(bit_field).to have_property(:width, 32)
      expect(bit_field).to have_property(:type, :rw)
      expect(bit_field).to have_property(:initial_value, 0)
      expect(bit_field).to have_property(:comment, '0: input, 1: output')

      # reg data_out
      register = register_block.registers[1]
      expect(register).to have_property(:name, 'data_out')
      expect(register).to have_property(:offset_address, 0x04)

      bit_field = register.bit_fields[0]
      expect(bit_field).to have_property(:name, 'value')
      expect(bit_field).to have_property(:lsb, 0)
      expect(bit_field).to have_property(:width, 32)
      expect(bit_field).to have_property(:type, :rw)
      expect(bit_field).to have_property(:initial_value, 0)

      # reg data_in
      register = register_block.registers[2]
      expect(register).to have_property(:name, 'data_in')
      expect(register).to have_property(:offset_address, 0x08)

      bit_field = register.bit_fields[0]
      expect(bit_field).to have_property(:name, 'value')
      expect(bit_field).to have_property(:lsb, 0)
      expect(bit_field).to have_property(:width, 32)
      expect(bit_field).to have_property(:type, :ro)
      expect(bit_field).to have_property(:comment, 'Value sampled from the pins')
    end
  end
end
