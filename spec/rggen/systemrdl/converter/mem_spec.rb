# frozen_string_literal: true

RSpec.describe RgGen::SystemRDL::Converter::Mem do
  include_context 'systemrdl common'

  it 'converts mem instance name into the external register name' do
    input_data = load_rdl(<<~RDL, :register)
      addrmap my_map {
        external mem { mementries = 64; memwidth = 32; } a;
        external mem { mementries = 64; memwidth = 32; } b[2];
        external mem { mementries = 64; memwidth = 32; } c[1][2];
      };
    RDL

    expect(input_data[0]).to have_value(:name, 'a')
    expect(input_data[1]).to have_value(:name, 'b__0')
    expect(input_data[2]).to have_value(:name, 'b__1')
    expect(input_data[3]).to have_value(:name, 'c__0__0')
    expect(input_data[4]).to have_value(:name, 'c__0__1')
  end

  it 'converts mem desc into the external register comment' do
    input_data = load_rdl(<<~RDL, :register)
      addrmap my_map {
        external mem { mementries = 64; memwidth = 32; desc = "memory a"; } a;
        external mem { mementries = 64; memwidth = 32; } b;
      };
    RDL

    expect(input_data[0]).to have_value(:comment, 'memory a')
    expect(input_data[1]).to have_value(:comment, '')
  end

  it 'converts mem address into the external register offset_address' do
    input_data = load_rdl(<<~RDL, :register, bus_width: 16)
      addrmap my_map {
        external mem { mementries = 1; memwidth = 32; } a @ 0x00;
        external mem { mementries = 1; memwidth = 32; } b @ 0x10;
        external mem { mementries = 1; memwidth = 16; } c @ 0x22;
      };
    RDL

    expect(input_data[0]).to have_value(:offset_address, 0x00)
    expect(input_data[1]).to have_value(:offset_address, 0x10)
    expect(input_data[2]).to have_value(:offset_address, 0x22)
  end

  it 'converts a mem into an external register' do
    input_data = load_rdl(<<~RDL, :register, bus_width: 32)
      addrmap my_map {
        external mem { mementries = 64; memwidth = 32; } a;
        external mem { mementries = 16; memwidth = 32; } b;
        external mem { mementries = 4;  memwidth = 64; } c;
      };
    RDL

    expect(input_data[0]).to have_value(:type, :external)
    expect(input_data[0]).to have_value(:size, 64)
    expect(input_data[1]).to have_value(:type, :external)
    expect(input_data[1]).to have_value(:size, 16)
    expect(input_data[2]).to have_value(:type, :external)
    expect(input_data[2]).to have_value(:size, 8)
  end

  describe 'error detection' do
    it 'raises an error when a reg identifier contains __' do
      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            external mem { mementries = 1; memwidth = 32; } a_b;
          };
        RDL
      }.not_to raise_error

      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            external mem { mementries = 1; memwidth = 32; } a__b;
          };
        RDL
      }.to raise_source_error 'identifier including __ is not allowed: a__b'

      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            external mem { mementries = 1; memwidth = 32; } a___b;
          };
        RDL
      }.to raise_source_error 'identifier including __ is not allowed: a___b'
    end

    it 'raises an error when the mem region size is not a multiple of the bus width' do
      expect {
        load_rdl(<<~RDL, :register, bus_width: 32)
          addrmap my_map {
            external mem { mementries = 1; memwidth = 16; } a @ 0x00;
          };
        RDL
      }.to raise_source_error 'mem size is not a multiple of the bus width: size 2 bus width 32'
    end
  end
end
