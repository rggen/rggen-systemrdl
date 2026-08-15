# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class Field < Base
        private

        def layer_name
          :bit_field
        end

        def unsupported_properties
          [:resetsignal, :wel, :swmod, :anded, :ored, :xored, :hwenable, :hwmask, :paritycheck]
        end

        def convert_rdl_model(rdl_model, _root_data, input_data)
          check_precedence(rdl_model, input_data)
          convert_name(rdl_model, input_data)
          convert_comment(rdl_model, input_data)
          convert_bit_assignment(rdl_model, input_data)
          convert_initial_value(rdl_model, input_data)
          convert_type(rdl_model, input_data)
        end

        def check_precedence(rdl_model, input_data)
          return if input_data.configuration.ignore_precedence?

          precedence = rdl_model.property(:precedence)
          return if precedence.value == :hw

          error 'sw precedence is not supported', precedence.token_range
        end

        def convert_bit_assignment(rdl_model, input_data)
          lsb = from_property(rdl_model, :lsb)
          width = from_property(rdl_model, :width)
          input_data[:bit_assignment] = { lsb:, width: }
        end

        def convert_initial_value(rdl_model, input_data)
          reset = rdl_model.property(:reset)

          reset.value? ||
            (error 'reset given as a reference is not supported', reset.token_range)

          input_data[:initial_value] = from_property_value(reset) if reset.value
        end

        def convert_type(rdl_model, input_data)
          return if [
            :convert_rw, :convert_rof, :convert_ro_ext, :convert_ro_ref, :convert_wo, :convert_rohw,
            :convert_rwhw, :convert_rc, :convert_rs, :convert_wrc, :convert_wrs, :convert_w0c,
            :convert_w1c, :convert_w0s, :convert_w1s, :convert_w0t, :convert_w1t, :convert_wc,
            :convert_woc, :convert_ws, :convert_wos, :convert_w0crs, :convert_w1crs, :convert_wcrs,
            :convert_w0src, :convert_w1src, :convert_wsrc, :convert_rwl, :convert_rwe, :convert_rwc,
            :convert_rws, :convert_rwtrg, :convert_rotrg_ext, :convert_rotrg_ref, :convert_wotrg,
            :convert_w1trg, :convert_w1, :convert_wo1
          ].any? { |converter| __send__(converter, rdl_model, input_data) }

          error 'no corresponding bit field type', rdl_model.token_range
        end

        def convert_rw(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw)

          sw = rdl_model.sw
          hw = rdl_model.hw
          return unless sw == :rw && (hw in :na | :r)

          input_data[:type] = to_input_value(:rw, nil)
        end

        def convert_rof(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw)

          sw = rdl_model.sw
          hw = rdl_model.hw
          reset = rdl_model.property(:reset)
          return unless sw == :r && hw == :na && reset

          input_data[:type] = :rof
        end

        def convert_ro_ext(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw)

          sw = rdl_model.sw
          hw = rdl_model.hw
          return unless sw == :r && (hw in :rw | :w)

          input_data[:type] = to_input_value(:ro, nil)
        end

        def convert_ro_ref(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :next)

          sw = rdl_model.sw
          hw = rdl_model.hw
          ref = rdl_model.property(:next)
          return unless sw == :r && (hw in :na | :r) && ref.value

          input_data[:type] = to_input_value(:ro, nil)
          input_data[:reference] = from_property_value(ref)
        end

        def convert_wo(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw)

          sw = rdl_model.sw
          hw = rdl_model.hw
          return unless sw == :w && (hw in :na | :r)

          input_data[:type] = :wo
        end

        def convert_rohw(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :we)

          sw = rdl_model.sw
          hw = rdl_model.hw
          we = rdl_model.property(:we)
          return unless sw == :r && (hw in :rw | :w) && we.value

          input_data[:reference] = from_property_value(we) if we.instance_ref?
          input_data[:type] = to_input_value(:rohw, nil)
        end

        def convert_rwhw(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :we)

          sw = rdl_model.sw
          hw = rdl_model.hw
          we = rdl_model.property(:we)
          return unless sw == :rw && (hw in :rw | :w) && we.value

          input_data[:reference] = from_property_value(we) if we.instance_ref?
          input_data[:type] = to_input_value(:rwhw, nil)
        end

        def convert_rc(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :rclr, :onread, :hwset)

          sw = rdl_model.sw
          hw = rdl_model.hw
          rclr = rdl_model.rclr || rdl_model.onread == :rclr
          hwset = set_true?(rdl_model, :hwset)
          return unless sw == :r && (hw in :na | :r) && rclr && hwset

          input_data[:type] = to_input_value(:rc, nil)
        end

        def convert_rs(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :rset, :onread, :hwclr)

          sw = rdl_model.sw
          hw = rdl_model.hw
          rset = rdl_model.rset || rdl_model.onread == :rset
          hwclr = set_true?(rdl_model, :hwclr)
          return unless sw == :r && (hw in :na | :r) && rset && hwclr

          input_data[:type] = to_input_value(:rs, nil)
        end

        def convert_wrc(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :rclr, :onread)

          sw = rdl_model.sw
          hw = rdl_model.hw
          rclr = rdl_model.rclr || rdl_model.onread == :rclr
          return unless sw == :rw && (hw in :na | :r) && rclr

          input_data[:type] = to_input_value(:wrc, nil)
        end

        def convert_wrs(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :rset, :onread)

          sw = rdl_model.sw
          hw = rdl_model.hw
          rset = rdl_model.rset || rdl_model.onread == :rset
          return unless sw == :rw && (hw in :na | :r) && rset

          input_data[:type] = to_input_value(:wrs, nil)
        end

        def convert_w0c(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite, :hwset)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wzc = rdl_model.onwrite == :wzc
          hwset = set_true?(rdl_model, :hwset)
          return unless sw == :rw && (hw in :na | :r) && wzc && hwset

          input_data[:type] = to_input_value(:w0c, nil)
        end

        def convert_w1c(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :woclr, :onwrite, :hwset)

          sw = rdl_model.sw
          hw = rdl_model.hw
          woclr = rdl_model.woclr || rdl_model.onwrite == :woclr
          hwset = set_true?(rdl_model, :hwset)
          return unless sw == :rw && (hw in :na | :r) && woclr && hwset

          input_data[:type] = to_input_value(:w1c, nil)
        end

        def convert_w0s(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite, :hwclr)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wzs = rdl_model.onwrite == :wzs
          hwclr = set_true?(rdl_model, :hwclr)
          return unless sw == :rw && (hw in :na | :r) && wzs && hwclr

          input_data[:type] = to_input_value(:w0s, nil)
        end

        def convert_w1s(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :woset, :onwrite, :hwclr)

          sw = rdl_model.sw
          hw = rdl_model.hw
          woset = rdl_model.woset || rdl_model.onwrite == :woset
          hwclr = set_true?(rdl_model, :hwclr)
          return unless sw == :rw && (hw in :na | :r) && woset && hwclr

          input_data[:type] = to_input_value(:w1s, nil)
        end

        def convert_w0t(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wzt = rdl_model.onwrite == :wzt
          return unless sw == :rw && (hw in :na | :r) && wzt

          input_data[:type] = to_input_value(:w0t, nil)
        end

        def convert_w1t(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wot = rdl_model.onwrite == :wot
          return unless sw == :rw && (hw in :na | :r) && wot

          input_data[:type] = to_input_value(:w1t, nil)
        end

        def convert_wc(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite, :hwset)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wclr = rdl_model.onwrite == :wclr
          hwset = set_true?(rdl_model, :hwset)
          return unless sw == :rw && (hw in :na | :r) && wclr && hwset

          input_data[:type] = to_input_value(:wc, nil)
        end

        def convert_woc(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite, :hwset)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wclr = rdl_model.onwrite == :wclr
          hwset = set_true?(rdl_model, :hwset)
          return unless sw == :w && (hw in :na | :r) && wclr && hwset

          input_data[:type] = to_input_value(:woc, nil)
        end

        def convert_ws(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite, :hwclr)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wset = rdl_model.onwrite == :wset
          hwclr = set_true?(rdl_model, :hwclr)
          return unless sw == :rw && (hw in :na | :r) && wset && hwclr

          input_data[:type] = to_input_value(:ws, nil)
        end

        def convert_wos(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite, :hwclr)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wset = rdl_model.onwrite == :wset
          hwclr = set_true?(rdl_model, :hwclr)
          return unless sw == :w && (hw in :na | :r) && wset && hwclr

          input_data[:type] = to_input_value(:wos, nil)
        end

        def convert_w0crs(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite, :rset, :onread)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wzc = rdl_model.onwrite == :wzc
          rset = rdl_model.rset || rdl_model.onread == :rset
          return unless sw == :rw && (hw in :na | :r) && wzc && rset

          input_data[:type] = to_input_value(:w0crs, nil)
        end

        def convert_w1crs(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :woclr, :onwrite, :rset, :onread)

          sw = rdl_model.sw
          hw = rdl_model.hw
          woclr = rdl_model.woclr || rdl_model.onwrite == :woclr
          rset = rdl_model.rset || rdl_model.onread == :rset
          return unless sw == :rw && (hw in :na | :r) && woclr && rset

          input_data[:type] = to_input_value(:w1crs, nil)
        end

        def convert_wcrs(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite, :rset, :onread)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wclr = rdl_model.onwrite == :wclr
          rset = rdl_model.rset || rdl_model.onread == :rset
          return unless sw == :rw && (hw in :na | :r) && wclr && rset

          input_data[:type] = to_input_value(:wcrs, nil)
        end

        def convert_w0src(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite, :rclr, :onread)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wzs = rdl_model.onwrite == :wzs
          rclr = rdl_model.rclr || rdl_model.onread == :rclr
          return unless sw == :rw && (hw in :na | :r) && wzs && rclr

          input_data[:type] = to_input_value(:w0src, nil)
        end

        def convert_w1src(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :woset, :onwrite, :rclr, :onread)

          sw = rdl_model.sw
          hw = rdl_model.hw
          woset = rdl_model.woset || rdl_model.onwrite == :woset
          rclr = rdl_model.rclr || rdl_model.onread == :rclr
          return unless sw == :rw && (hw in :na | :r) && woset && rclr

          input_data[:type] = to_input_value(:w1src, nil)
        end

        def convert_wsrc(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :onwrite, :rclr, :onread)

          sw = rdl_model.sw
          hw = rdl_model.hw
          wset = rdl_model.onwrite == :wset
          rclr = rdl_model.rclr || rdl_model.onread == :rclr
          return unless sw == :rw && (hw in :na | :r) && wset && rclr

          input_data[:type] = to_input_value(:wsrc, nil)
        end

        def convert_rwl(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :swwel)

          sw = rdl_model.sw
          hw = rdl_model.hw
          swwel = rdl_model.property(:swwel)
          return unless sw == :rw && (hw in :na | :r) && swwel.value

          input_data[:reference] = from_property_value(swwel) if swwel.instance_ref?
          input_data[:type] = to_input_value(:rwl, nil)
        end

        def convert_rwe(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :swwe)

          sw = rdl_model.sw
          hw = rdl_model.hw
          swwe = rdl_model.property(:swwe)
          return unless sw == :rw && (hw in :na | :r) && swwe.value

          input_data[:reference] = from_property_value(swwe) if swwe.instance_ref?
          input_data[:type] = to_input_value(:rwe, nil)
        end

        def convert_rwc(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :hwclr)

          sw = rdl_model.sw
          hw = rdl_model.hw
          hwclr = rdl_model.property(:hwclr)
          return unless sw == :rw && (hw in :na | :r) && hwclr.value

          input_data[:reference] = from_property_value(hwclr) if hwclr.instance_ref?
          input_data[:type] = to_input_value(:rwc, nil)
        end

        def convert_rws(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :hwset)

          sw = rdl_model.sw
          hw = rdl_model.hw
          hwset = rdl_model.property(:hwset)
          return unless sw == :rw && (hw in :na | :r) && hwset.value

          input_data[:reference] = from_property_value(hwset) if hwset.instance_ref?
          input_data[:type] = to_input_value(:rws, nil)
        end

        def convert_rwtrg(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :swacc)

          sw = rdl_model.sw
          hw = rdl_model.hw
          swacc = rdl_model.swacc
          return unless sw == :rw && (hw in :na | :r) && swacc

          input_data[:type] = to_input_value(:rwtrg, nil)
        end

        def convert_rotrg_ext(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :swacc)

          sw = rdl_model.sw
          hw = rdl_model.hw
          swacc = rdl_model.swacc
          return unless sw == :r && (hw in :rw | :w) && swacc

          input_data[:type] = to_input_value(:rotrg, nil)
        end

        def convert_rotrg_ref(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :next, :swacc)

          sw = rdl_model.sw
          hw = rdl_model.hw
          ref = rdl_model.property(:next)
          swacc = rdl_model.swacc
          return unless sw == :r && (hw in :na | :r) && ref.value && swacc

          input_data[:reference] = from_property_value(ref)
          input_data[:type] = to_input_value(:rotrg, nil)
        end

        def convert_wotrg(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :swacc)

          sw = rdl_model.sw
          hw = rdl_model.hw
          swacc = rdl_model.swacc
          return unless sw == :w && (hw in :na | :r) && swacc

          input_data[:type] = to_input_value(:wotrg, nil)
        end

        def convert_w1trg(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw, :singlepulse)

          sw = rdl_model.sw
          hw = rdl_model.hw
          singlepulse = rdl_model.singlepulse
          return unless sw == :rw && (hw in :na | :r) && singlepulse

          input_data[:type] = to_input_value(:w1trg, nil)
        end

        def convert_w1(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw)

          sw = rdl_model.sw
          hw = rdl_model.hw
          return unless sw == :rw1 && (hw in :na | :r)

          input_data[:type] = to_input_value(:w1, nil)
        end

        def convert_wo1(rdl_model, input_data)
          return unless only_set?(rdl_model, :sw, :hw)

          sw = rdl_model.sw
          hw = rdl_model.hw
          return unless sw == :w1 && (hw in :na | :r)

          input_data[:type] = to_input_value(:wo1, nil)
        end

        def only_set?(rdl_model, *allowed_properties)
          properties = [
            :sw, :hw, :next, :onread, :rclr, :rset, :onwrite, :woset, :woclr,
            :swwe, :swwel, :swacc, :singlepulse, :we, :hwclr, :hwset
          ]
          (properties - allowed_properties).none? do |property|
            rdl_model.property(property).value
          end
        end
      end
    end
  end
end
