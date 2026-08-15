# frozen_string_literal: true

RSpec.describe RgGen::SystemRDL::Converter::AddrMap do
  include_context 'systemrdl common'

  it 'converts a root addrmap name into the register_block name' do
    input_data = load_rdl(<<~RDL, :register_block)
      addrmap my_map {
        reg { field { sw = rw; hw = r; } a; } a;
      };
    RDL

    expect(input_data[0]).to have_value(:name, 'my_map')
  end

  it 'converts a nested addrmap into its own register_block with a __-joined name' do
    input_data = load_rdl(<<~RDL, :register_block)
      addrmap my_map {
        addrmap {
          reg { field { sw = rw; hw = r; } a; } a;
        } a;
        addrmap {
          reg { field { sw = rw; hw = r; } b; } b;
        } b[2];
        addrmap {
          reg { field { sw = rw; hw = r; } c; } c;
        } c[1][2];
      };
    RDL

    expect(input_data[1]).to have_value(:name, 'my_map__a')
    expect(input_data[2]).to have_value(:name, 'my_map__b__0')
    expect(input_data[3]).to have_value(:name, 'my_map__b__1')
    expect(input_data[4]).to have_value(:name, 'my_map__c__0__0')
    expect(input_data[5]).to have_value(:name, 'my_map__c__0__1')
  end

  it 'converts addrmap desc into the comment' do
    input_data = load_rdl(<<~RDL, :register_block)
      addrmap my_map {
        desc = "root block";
        addrmap {
          desc = "nested block";
          reg { field { sw = rw; hw = r; } a; } a;
        } a;
        addrmap {
          reg { field { sw = rw; hw = r; } b; } b;
        } b;
      };
    RDL

    expect(input_data[0]).to have_value(:comment, 'root block')
    expect(input_data[1]).to have_value(:comment, 'nested block')
    expect(input_data[2]).to have_value(:comment, '')
  end

  it 'converts addrmap size into the register_block byte_size' do
    input_data = load_rdl(<<~RDL, :register_block)
      addrmap my_map {
        reg { field { sw = rw; hw = r; } a; } a @ 0x00;
        addrmap {
          reg { field { sw = rw; hw = r; } b; } b;
        } b @0x10;
      };
    RDL

    expect(input_data[0]).to have_value(:byte_size, 20)
    expect(input_data[1]).to have_value(:byte_size, 4)
  end

  it 'reserves a nested addrmap as an external register on the enclosing map' do
    input_data = load_rdl(<<~RDL, :register_block)
      addrmap my_map {
        addrmap {
          desc = "nested block";
          reg { field { sw = rw; hw = r; } a; } a @ 0x00;
        } a @ 0x10;
      };
    RDL

    register = input_data[0].children[0]
    expect(register).to have_value(:name, 'a')
    expect(register).to have_value(:comment, 'nested block')
    expect(register).to have_value(:offset_address, 0x10)
    expect(register).to have_value(:type, :external)
    expect(register).to have_value(:size, 1)
  end

  describe 'error detection' do
    it 'raises an error when an addrmap identifier contains __' do
      expect {
        load_rdl(<<~RDL, :register_block)
          addrmap my_map {
            reg { field { sw = rw; hw = r; } a; } a;
          };
        RDL
      }.not_to raise_error

      expect {
        load_rdl(<<~RDL, :register_block)
          addrmap my__map {
            reg { field { sw = rw; hw = r; } a; } a;
          };
        RDL
      }.to raise_source_error 'identifier including __ is not allowed: my__map'

      expect {
        load_rdl(<<~RDL, :register_block)
          addrmap my___map {
            reg { field { sw = rw; hw = r; } a; } a;
          };
        RDL
      }.to raise_source_error 'identifier including __ is not allowed: my___map'
    end

    it 'raises an error when an unsupported property is set' do
      [:sharedextbus, :bigendian, :littleendian, :rsvdset, :rsvdsetX, :msb0].each do |prop_name|
        expect {
          load_rdl(<<~RDL, :register_block)
            addrmap my_map {
              #{prop_name} = true;
              reg { field { sw = rw; hw = r; } a; } a;
            };
          RDL
        }.to raise_source_error "#{prop_name} is not supported"
      end
    end

    it 'ignores errextbus without raising an error' do
      expect {
        load_rdl(<<~RDL, :register_block)
          addrmap my_map {
            errextbus = true;
            reg { field { sw = rw; hw = r; } a; } a;
          };
        RDL
      }.not_to raise_error
    end
  end
end
