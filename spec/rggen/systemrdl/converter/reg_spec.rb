# frozen_string_literal: true

RSpec.describe RgGen::SystemRDL::Converter::Reg do
  include_context 'systemrdl common'

  it 'converts reg instance name into the register name' do
    input_data = load_rdl(<<~RDL, :register)
      addrmap my_map {
        reg {
          field { sw = rw; hw = r; } a;
        } a;
        reg {
          field { sw = rw; hw = r; } a;
        } b[2];
        reg {
          field { sw = rw; hw = r; } c;
        } c[1][2];
      };
    RDL

    expect(input_data[0]).to have_value(:name, 'a')
    expect(input_data[1]).to have_value(:name, 'b__0')
    expect(input_data[2]).to have_value(:name, 'b__1')
    expect(input_data[3]).to have_value(:name, 'c__0__0')
    expect(input_data[4]).to have_value(:name, 'c__0__1')
  end

  it 'converts reg desc into the register comment' do
    input_data = load_rdl(<<~RDL, :register)
      addrmap my_map {
        reg { field { sw = rw; hw = r; } a; desc = "register a"; } a;
        reg { field { sw = rw; hw = r; } a; } b;
      };
    RDL

    expect(input_data[0]).to have_value(:comment, 'register a')
    expect(input_data[1]).to have_value(:comment, '')
  end

  it 'converts reg address into the register offset_address' do
    input_data = load_rdl(<<~RDL, :register)
      addrmap my_map {
        reg { regwidth = 32; field { sw = rw; hw = r; } a; } a @ 0x00;
        reg { regwidth = 16; field { sw = rw; hw = r; } a; } b @ 0x10;
        reg { regwidth = 16; field { sw = rw; hw = r; } a; } c @ 0x22;
      };
    RDL

    expect(input_data[0]).to have_value(:offset_address, 0x00)
    expect(input_data[1]).to have_value(:offset_address, 0x10)
    expect(input_data[2]).to have_value(:offset_address, 0x22)
  end

  describe 'error detection' do
    it 'raises an error when a reg identifier contains __' do
      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            reg {
              field { sw = rw; hw = r; } a;
            } a_b;
          };
        RDL
      }.not_to raise_error

      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            reg {
              field { sw = rw; hw = r; } a;
            } a__b;
          };
        RDL
      }.to raise_source_error 'identifier including __ is not allowed: a__b'

      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            reg {
              field { sw = rw; hw = r; } a;
            } a___b;
          };
        RDL
      }.to raise_source_error 'identifier including __ is not allowed: a___b'
    end

    it 'raises a source error when an unsupported property is set' do
      [:shared].each do |prop_name|
        expect {
          load_rdl(<<~RDL, :bit_field)
            addrmap my_map {
              reg {
                #{prop_name} = true;
                field { sw = rw; hw = r; } a;
              } a;
            };
          RDL
        }.to raise_source_error "#{prop_name} is not supported"
      end
    end

    it 'ignores errextbus and accesswidth without raising an error' do
      expect {
        load_rdl(<<~RDL, :register)
          addrmap my_map {
            reg { field { sw = rw; hw = r; } a; errextbus   = true; } a;
            reg { field { sw = rw; hw = r; } a; accesswidth = 32  ; } b;
          };
        RDL
      }.not_to raise_error
    end

    it 'raises an error when a reg is external' do
      expect {
        load_rdl(<<~RDL, :register)
          addrmap my_map {
            external reg { field { sw = rw; hw = r; } a; } a;
          };
        RDL
      }.to raise_source_error 'external reg is not supported'
    end
  end
end
