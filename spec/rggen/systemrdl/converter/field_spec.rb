# frozen_string_literal: true

RSpec.describe RgGen::SystemRDL::Converter::Field do
  include_context 'systemrdl common'

  it 'converts field bit width and lsb into the bit_field bit_assignment' do
    input_data = load_rdl(<<~RDL, :bit_field)
      addrmap my_map {
        reg {
          field { sw = rw; hw = r; } a[1];
          field { sw = rw; hw = r; } b[2];
          field { sw = rw; hw = r; } c[23:16];
        } a;
      };
    RDL

    expect(input_data[0]).to have_value(:bit_assignment, { lsb: 0, width: 1 })
    expect(input_data[1]).to have_value(:bit_assignment, { lsb: 1, width: 2 })
    expect(input_data[2]).to have_value(:bit_assignment, { lsb: 16, width: 8 })
  end
end
