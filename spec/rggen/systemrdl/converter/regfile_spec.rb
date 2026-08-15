# frozen_string_literal: true

RSpec.describe RgGen::SystemRDL::Converter::RegFile do
  include_context 'systemrdl common'

  it 'converts regfile instance name into the register_file name' do
    input_data = load_rdl(<<~RDL, :register_file)
      addrmap my_map {
        regfile my_regfile {
          reg { field { sw = rw; hw = r; } a; } a;
        };
        my_regfile a;
        my_regfile b[2];
        my_regfile c[1][2];
      };
    RDL

    expect(input_data[0]).to have_value(:name, 'a')
    expect(input_data[1]).to have_value(:name, 'b__0')
    expect(input_data[2]).to have_value(:name, 'b__1')
    expect(input_data[3]).to have_value(:name, 'c__0__0')
    expect(input_data[4]).to have_value(:name, 'c__0__1')
  end

  it 'converts regfile desc into the register_file comment' do
    input_data = load_rdl(<<~RDL, :register_file)
      addrmap my_map {
        reg my_reg { field { sw = rw; hw = r; } a; };
        regfile { my_reg a; desc = "register file a"; } a;
        regfile { my_reg a; } b;
      };
    RDL

    expect(input_data[0]).to have_value(:comment, 'register file a')
    expect(input_data[1]).to have_value(:comment, '')
  end

  it 'converts regfile address into the register_file offset_address' do
    input_data = load_rdl(<<~RDL, :register_file)
      addrmap my_map {
        regfile { reg { regwidth = 32; field { sw = rw; hw = r; } a; } a; } a @ 0x00;
        regfile { reg { regwidth = 16; field { sw = rw; hw = r; } a; } b; } b @ 0x10;
        regfile { reg { regwidth = 16; field { sw = rw; hw = r; } a; } c; } c @ 0x22;
      };
    RDL

    expect(input_data[0]).to have_value(:offset_address, 0x00)
    expect(input_data[1]).to have_value(:offset_address, 0x10)
    expect(input_data[2]).to have_value(:offset_address, 0x22)
  end

  describe 'error detection' do
    it 'raises an error when a regfile identifier contains __' do
      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            regfile {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
            } a_b;
          };
        RDL
      }.not_to raise_error

      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            regfile {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
            } a__b;
          };
        RDL
      }.to raise_source_error 'identifier including __ is not allowed: a__b'

      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            regfile {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
            } a___b;
          };
        RDL
      }.to raise_source_error 'identifier including __ is not allowed: a___b'
    end

    it 'raises a source error when an unsupported property is set' do
      [:sharedextbus].each do |prop_name|
        expect {
          load_rdl(<<~RDL, :bit_field)
            addrmap my_map {
              regfile {
                #{prop_name} = true;
                reg { field { sw = rw; hw = r; } a; } a;
              } a;
            };
          RDL
        }.to raise_source_error "#{prop_name} is not supported"
      end
    end

    it 'ignores errextbus without raising an error' do
      expect {
        load_rdl(<<~RDL, :register_file)
          addrmap my_map {
            regfile {
              reg { field { sw = rw; hw = r; } a; } a;
              errextbus = true;
            } a;
          };
        RDL
      }.not_to raise_error
    end

    it 'raises an error when a reg is external' do
      expect {
        load_rdl(<<~RDL, :register)
          addrmap my_map {
            external regfile {
              reg { field { sw = rw; hw = r; } a; } a;
            } a;
          };
        RDL
      }.to raise_source_error 'external regfile is not supported'
    end
  end
end
