# frozen_string_literal: true

RSpec.describe RgGen::SystemRDL::Converter::Field do
  include_context 'systemrdl common'

  it 'converts field instance name into the bit_field name' do
    input_data = load_rdl(<<~RDL, :bit_field)
      addrmap my_map {
        reg {
          field { sw = rw; hw = r; } a;
          field { sw = rw; hw = r; } b;
        } a;
      };
    RDL

    expect(input_data[0]).to have_value(:name, 'a')
    expect(input_data[1]).to have_value(:name, 'b')
  end

  it 'converts field desc into the bit_field comment' do
    input_data = load_rdl(<<~RDL, :bit_field)
      addrmap my_map {
        reg {
          field { sw = rw; hw = r; desc = "field a"; } a;
          field { sw = rw; hw = r; } b;
        } a;
      };
    RDL

    expect(input_data[0]).to have_value(:comment, 'field a')
    expect(input_data[1]).to have_value(:comment, '')
  end

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

  it 'converts field reset into the bit_field initial_value' do
    input_data = load_rdl(<<~RDL, :bit_field)
      addrmap my_map {
        reg {
          field { sw = rw; hw = r; reset = 1'b1;  } a[1];
          field { sw = rw; hw = r; reset = 8'hff; } b[23:16];
          field { sw = rw; hw = r;                } c;
        } a;
      };
    RDL

    expect(input_data[0]).to have_value(:initial_value, 1)
    expect(input_data[1]).to have_value(:initial_value, 0xff)
    expect(input_data[2]).not_to have_value(:initial_value)
  end

  describe 'type conversion' do
    it 'converts sw=rw, hw=r/na into the rw type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  } a;
            field { sw = rw; hw = na; } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rw)
      expect(input_data[1]).to have_value(:type, :rw)
    end

    it 'converts sw=r (hw=rw/w, or next reference) into the ro type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = r; hw = rw; } a;
            field { sw = r; hw = w;  } b;
            field { sw = r; hw = w;  } c;
            field { sw = r; hw = r;  } d;
            d->next = c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :ro)
      expect(input_data[0]).not_to have_value(:reference)
      expect(input_data[1]).to have_value(:type, :ro)
      expect(input_data[1]).not_to have_value(:reference)
      expect(input_data[3]).to have_value(:type, :ro)
      expect(input_data[3]).to have_value(:reference, 'a.c')
    end

    it 'converts sw=r, hw=na into the rof type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = r; hw = na; reset = 8'hff; } a[7:0];
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rof)
      expect(input_data[0]).to have_value(:initial_value, 0xff)
    end

    it 'converts sw=w, hw=r/na into the wo type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = w; hw = r; } a;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :wo)
    end

    it 'converts sw=r, hw=rw/w, we (true or reference) into the rohw type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = r; hw = rw; we = true; } a;
            field { sw = r; hw = w;  we = true; } b;
            field { sw = rw; hw = r; } c;
            field { sw = r; hw = rw; } d;
            d->we = c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rohw)
      expect(input_data[0]).not_to have_value(:reference)
      expect(input_data[1]).to have_value(:type, :rohw)
      expect(input_data[1]).not_to have_value(:reference)
      expect(input_data[3]).to have_value(:type, :rohw)
      expect(input_data[3]).to have_value(:reference, 'a.c')
    end

    it 'converts sw=rw, hw=rw/w, we (true or reference) into the rwhw type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = rw; we = true; } a;
            field { sw = rw; hw = w;  we = true; } b;
            field { sw = rw; hw = r;  } c;
            field { sw = r ; hw = rw; } d;
            d->sw = rw;
            d->we = c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rwhw)
      expect(input_data[0]).not_to have_value(:reference)
      expect(input_data[1]).to have_value(:type, :rwhw)
      expect(input_data[1]).not_to have_value(:reference)
      expect(input_data[3]).to have_value(:type, :rwhw)
      expect(input_data[3]).to have_value(:reference, 'a.c')
    end

    it 'converts sw=r, onread=rclr, hwset into the rc type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = r; hw = r; hwset = true; onread = rclr; } a;
            field { sw = r; hw = r; hwset = true; rclr;          } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rc)
      expect(input_data[1]).to have_value(:type, :rc)
    end

    it 'converts sw=r, onread=rset, hwclr into the rs type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = r; hw = r; hwclr = true; onread = rset; } a;
            field { sw = r; hw = r; hwclr = true; rset;          } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rs)
      expect(input_data[1]).to have_value(:type, :rs)
    end

    it 'converts sw=rw, hw=r/na, onread=rclr into the wrc type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onread = rclr; } a;
            field { sw = rw; hw = na; onread = rclr; } b;
            field { sw = rw; hw = na; rclr;          } c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :wrc)
      expect(input_data[1]).to have_value(:type, :wrc)
      expect(input_data[2]).to have_value(:type, :wrc)
    end

    it 'converts sw=rw, hw=r/na, onread=rset into the wrs type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onread = rset; } a;
            field { sw = rw; hw = na; onread = rset; } b;
            field { sw = rw; hw = na; rset;          } c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :wrs)
      expect(input_data[1]).to have_value(:type, :wrs)
      expect(input_data[2]).to have_value(:type, :wrs)
    end

    it 'converts sw=rw, hw=r/na, onwrite=wzc, hwset into the w0c type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  hwset = true; onwrite = wzc; } a;
            field { sw = rw; hw = na; hwset = true; onwrite = wzc; } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w0c)
      expect(input_data[1]).to have_value(:type, :w0c)
    end

    it 'converts sw=rw, hw=r/na, onwrite=woclr, hwset into the w1c type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  hwset = true; onwrite = woclr; } a;
            field { sw = rw; hw = na; hwset = true; onwrite = woclr; } b;
            field { sw = rw; hw = na; hwset = true; woclr;           } c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w1c)
      expect(input_data[1]).to have_value(:type, :w1c)
      expect(input_data[2]).to have_value(:type, :w1c)
    end

    it 'converts sw=rw, hw=r/na, onwrite=wzs, hwclr into the w0s type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = wzs; hwclr = true; } a;
            field { sw = rw; hw = na; onwrite = wzs; hwclr = true; } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w0s)
      expect(input_data[1]).to have_value(:type, :w0s)
    end

    it 'converts sw=rw, hw=r/na, onwrite=woset, hwclr into the w1s type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = woset; hwclr = true; } a;
            field { sw = rw; hw = na; onwrite = woset; hwclr = true; } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w1s)
      expect(input_data[1]).to have_value(:type, :w1s)
    end

    it 'converts sw=rw, hw=r/na, onwrite=wzt into the w0t type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = wzt; } a;
            field { sw = rw; hw = na; onwrite = wzt; } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w0t)
      expect(input_data[1]).to have_value(:type, :w0t)
    end

    it 'converts sw=rw, hw=r/na, onwrite=wot into the w1t type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = wot; } a;
            field { sw = rw; hw = na; onwrite = wot; } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w1t)
      expect(input_data[1]).to have_value(:type, :w1t)
    end

    it 'converts sw=rw, hw=r/na, onwrite=wclr, hwset into the wc type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  hwset = true; onwrite = wclr; } a;
            field { sw = rw; hw = na; hwset = true; onwrite = wclr; } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :wc)
      expect(input_data[1]).to have_value(:type, :wc)
    end

    it 'converts sw=rw, hw=r/na, onwrite=wset, hwclr into the ws type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = wset; hwclr = true; } a;
            field { sw = rw; hw = na; onwrite = wset; hwclr = true; } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :ws)
      expect(input_data[1]).to have_value(:type, :ws)
    end

    it 'converts sw=w, hw=r/na, onwrite=wclr, hwset into the woc type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = w; hw = r; onwrite = wclr; hwset = true; } a;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :woc)
    end

    it 'converts sw=w, hw=r/na, onwrite=wset, hwclr into the wos type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = w; hw = r; onwrite = wset; hwclr = true; } a;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :wos)
    end

    it 'converts sw=rw, hw=r/na, onwrite=wzc, onread=rset into the w0crs type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = wzc; onread = rset; } a;
            field { sw = rw; hw = na; onwrite = wzc; onread = rset; } b;
            field { sw = rw; hw = na; onwrite = wzc; rset;          } c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w0crs)
      expect(input_data[1]).to have_value(:type, :w0crs)
      expect(input_data[2]).to have_value(:type, :w0crs)
    end

    it 'converts sw=rw, hw=r/na, onwrite=woclr, onread=rset into the w1crs type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = woclr; onread = rset; } a;
            field { sw = rw; hw = na; onwrite = woclr; onread = rset; } b;
            field { sw = rw; hw = na; woclr          ; rset;          } c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w1crs)
      expect(input_data[1]).to have_value(:type, :w1crs)
      expect(input_data[2]).to have_value(:type, :w1crs)
    end

    it 'converts sw=rw, hw=r/na, onwrite=wclr, onread=rset into the wcrs type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = wclr; onread = rset; } a;
            field { sw = rw; hw = na; onwrite = wclr; onread = rset; } b;
            field { sw = rw; hw = na; onwrite = wclr; rset;          } c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :wcrs)
      expect(input_data[1]).to have_value(:type, :wcrs)
      expect(input_data[2]).to have_value(:type, :wcrs)
    end

    it 'converts sw=rw, hw=r/na, onwrite=wzs, onread=rclr into the w0src type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = wzs; onread = rclr; } a;
            field { sw = rw; hw = na; onwrite = wzs; onread = rclr; } b;
            field { sw = rw; hw = na; onwrite = wzs; rclr;          } c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w0src)
      expect(input_data[1]).to have_value(:type, :w0src)
      expect(input_data[2]).to have_value(:type, :w0src)
    end

    it 'converts sw=rw, hw=r/na, onwrite=woset, onread=rclr into the w1src type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = woset; onread = rclr; } a;
            field { sw = rw; hw = na; onwrite = woset; onread = rclr; } b;
            field { sw = rw; hw = na; woset;           rclr;          } c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w1src)
      expect(input_data[1]).to have_value(:type, :w1src)
      expect(input_data[2]).to have_value(:type, :w1src)
    end

    it 'converts sw=rw, hw=r/na, onwrite=wset, onread=rclr into the wsrc type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  onwrite = wset; onread = rclr; } a;
            field { sw = rw; hw = na; onwrite = wset; onread = rclr; } b;
            field { sw = rw; hw = na; onwrite = wset; rclr;          } c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :wsrc)
      expect(input_data[1]).to have_value(:type, :wsrc)
      expect(input_data[2]).to have_value(:type, :wsrc)
    end

    it 'converts sw=rw, swwel (true or reference) into the rwl type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r; swwel = true; } a;
            field { sw = rw; hw = r; } b;
            field { sw = rw; hw = r; } c;
            c->swwel = b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rwl)
      expect(input_data[0]).not_to have_value(:reference)
      expect(input_data[2]).to have_value(:type, :rwl)
      expect(input_data[2]).to have_value(:reference, 'a.b')
    end

    it 'converts sw=rw, swwe (true or reference) into the rwe type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r; swwe = true; } a;
            field { sw = rw; hw = r; } b;
            field { sw = rw; hw = r; } c;
            c->swwe = b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rwe)
      expect(input_data[0]).not_to have_value(:reference)
      expect(input_data[2]).to have_value(:type, :rwe)
      expect(input_data[2]).to have_value(:reference, 'a.b')
    end

    it 'converts sw=rw, hw=r/na, hwclr (true or reference) into the rwc type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r; hwclr = true; } a;
            field { sw = rw; hw = r; } b;
            field { sw = rw; hw = r; } c;
            c->hwclr = b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rwc)
      expect(input_data[0]).not_to have_value(:reference)
      expect(input_data[2]).to have_value(:type, :rwc)
      expect(input_data[2]).to have_value(:reference, 'a.b')
    end

    it 'converts sw=rw, hw=r/na, hwset (true or reference) into the rws type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r; hwset = true; } a;
            field { sw = rw; hw = r; } b;
            field { sw = rw; hw = r; } c;
            c->hwset = b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rws)
      expect(input_data[0]).not_to have_value(:reference)
      expect(input_data[2]).to have_value(:type, :rws)
      expect(input_data[2]).to have_value(:reference, 'a.b')
    end

    it 'converts sw=rw, hw=r/na, swacc into the rwtrg type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  swacc = true; } a;
            field { sw = rw; hw = na; swacc = true; } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rwtrg)
      expect(input_data[1]).to have_value(:type, :rwtrg)
    end

    it 'converts sw=r, swacc (hw=rw/w, or next reference) into the rotrg type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = r; hw = rw; swacc = true; } a;
            field { sw = r; hw = w;  swacc = true; } b;
            field { sw = r; hw = w; } c;
            field { sw = r; hw = r; swacc = true; } d;
            d->next = c;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :rotrg)
      expect(input_data[0]).not_to have_value(:reference)
      expect(input_data[1]).to have_value(:type, :rotrg)
      expect(input_data[1]).not_to have_value(:reference)
      expect(input_data[3]).to have_value(:type, :rotrg)
      expect(input_data[3]).to have_value(:reference, 'a.c')
    end

    it 'converts sw=w, hw=r, swacc into the wotrg type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = w; hw = r; swacc = true; } a;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :wotrg)
    end

    it 'converts sw=rw, hw=r/na, singlepulse into the w1trg type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw; hw = r;  singlepulse = true; reset = 1; } a[1];
            field { sw = rw; hw = na; singlepulse = true; reset = 1; } b[1];
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w1trg)
      expect(input_data[1]).to have_value(:type, :w1trg)
    end

    it 'converts sw=rw1, hw=r/na into the w1 type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = rw1; hw = r;  } a;
            field { sw = rw1; hw = na; } b;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :w1)
      expect(input_data[1]).to have_value(:type, :w1)
    end

    it 'converts sw=w1, hw=r into the wo1 type' do
      input_data = load_rdl(<<~RDL, :bit_field)
        addrmap my_map {
          reg {
            field { sw = w1; hw = r; } a;
          } a;
        };
      RDL

      expect(input_data[0]).to have_value(:type, :wo1)
    end
  end

  describe 'precedence handling' do
    context 'when ignore_precedence is off' do
      it 'raises an error when the field precedence is sw' do
        expect {
          load_rdl(<<~RDL, :bit_field, ignore_precedence: false)
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; precedence = sw; } a;
              } a;
            };
          RDL
        }.to raise_source_error 'sw precedence is not supported'
      end

      it 'does not raise an error when the field precedence is hw' do
        expect {
          load_rdl(<<~RDL, :bit_field, ignore_precedence: false)
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; precedence = hw; } a;
              } a;
            };
          RDL
        }.not_to raise_error
      end
    end

    context 'when ignore_precedence is on' do
      it 'does not raise an error even when the field precedence is sw' do
        expect {
          load_rdl(<<~RDL, :bit_field, ignore_precedence: true)
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; precedence = sw; } a;
              } a;
            };
          RDL
        }.not_to raise_error
      end
    end
  end

  describe 'error detection' do
    it 'raises an error when a field identifier contains __' do
      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            reg {
              field { sw = rw; hw = r; } a_b;
            } a;
          };
        RDL
      }.not_to raise_error

      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            reg {
              field { sw = rw; hw = r; } a__b;
            } a;
          };
        RDL
      }.to raise_source_error 'identifier including __ is not allowed: a__b'

      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            reg {
              field { sw = rw; hw = r; } a___b;
            } a;
          };
        RDL
      }.to raise_source_error 'identifier including __ is not allowed: a___b'
    end

    it 'raises a source error when an unsupported property is set' do
      [:wel, :swmod, :anded, :ored, :xored, :paritycheck].each do |prop_name|
        expect {
          load_rdl(<<~RDL, :bit_field)
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; #{prop_name} = true; } a;
              } a;
            };
          RDL
        }.to raise_source_error "#{prop_name} is not supported"
      end

      [:hwenable, :hwmask, :resetsignal].each do |prop_name|
        expect {
          load_rdl(<<~RDL, :bit_field)
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
                field { sw = rw; hw = r; } b;
                b->#{prop_name} = a;
              } a;
            };
          RDL
        }.to raise_source_error "#{prop_name} is not supported"
      end
    end

    it 'raises an error when a property reference is given to a reference property' do
      [:next, :we, :swwe, :swwel, :hwclr, :hwset].each do |prop_name|
        expect {
          load_rdl(<<~RDL, :bit_field)
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
                field { sw = rw; hw = r; } b;
                b->#{prop_name} = a->anded;
              } a;
            };
          RDL
        }.to raise_source_error 'property reference is not supported'
      end
    end

    it 'raises an error when reset is given as a reference' do
      expect {
        load_rdl(<<~RDL, :bit_field)
          addrmap my_map {
            reg {
              field { sw = rw; hw = r; } a;
              field { sw = rw; hw = r; } b;
              b->reset = a;
            } a;
          };
        RDL
      }.to raise_source_error 'reset given as a reference is not supported'
    end

    it 'raises an error when the property combination fits no RgGen type' do
      [
        'field {sw = r;  hw = r;   onread  = ruser; } a;',
        'field {sw = rw; hw = r;   onwrite = wuser; } a;',
        'field {sw = rw; hw = r;   onwrite = wclr;  } a;', # wclr without hwset
        'field {sw = rw; hw = rw1; we = true;       } a;',
        'field {sw = rw; hw = w1;  we = true;       } a;',
      ].each do |field_def|
        expect {
          load_rdl(<<~RDL, :bit_field)
            addrmap my_map {
              reg {
                #{field_def}
              } a;
            };
          RDL
        }.to raise_source_error 'no corresponding bit field type'
      end

      # a bool-only required hwset/hwclr given as a reference → fits no type
      [
        # hwset=true required
        'field { sw = r;  hw = r; onread = rclr;                  } b; b->hwset = a;', # rc
        'field { sw = rw; hw = r; onwrite = wzc;                  } b; b->hwset = a;', # w0c
        'field { sw = rw; hw = r; onwrite = woclr;                } b; b->hwset = a;', # w1c
        'field { sw = rw; hw = r; onwrite = wclr;                 } b; b->hwset = a;', # wc
        'field { sw = w;  hw = r; onwrite = wclr;                 } b; b->hwset = a;', # woc
        'field { sw = rw; hw = r; onwrite = wzc;   onread = rset; } b; b->hwset = a;', # w0crs
        'field { sw = rw; hw = r; onwrite = woclr; onread = rset; } b; b->hwset = a;', # w1crs
        'field { sw = rw; hw = r; onwrite = wclr;  onread = rset; } b; b->hwset = a;', # wcrs
        # hwclr=true required
        'field { sw = r;  hw = r; onread = rset;                  } b; b->hwclr = a;', # rs
        'field { sw = rw; hw = r; onwrite = wzs;                  } b; b->hwclr = a;', # w0s
        'field { sw = rw; hw = r; onwrite = woset;                } b; b->hwclr = a;', # w1s
        'field { sw = rw; hw = r; onwrite = wset;                 } b; b->hwclr = a;', # ws
        'field { sw = w;  hw = r; onwrite = wset;                 } b; b->hwclr = a;', # wos
        'field { sw = rw; hw = r; onwrite = wzs;   onread = rclr; } b; b->hwclr = a;', # w0src
        'field { sw = rw; hw = r; onwrite = woset; onread = rclr; } b; b->hwclr = a;', # w1src
        'field { sw = rw; hw = r; onwrite = wset;  onread = rclr; } b; b->hwclr = a;'  # wsrc
      ].each do |field_def|
        expect {
          load_rdl(<<~RDL, :bit_field)
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
                #{field_def}
              } a;
            };
          RDL
        }.to raise_source_error 'no corresponding bit field type'
      end
    end
  end
end
