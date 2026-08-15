# frozen_string_literal: true

module RgGen
  module SystemRDL
    module Converter
      class Mem < Base
        private

        def support_external?
          true
        end

        def external?(_rdl_model)
          true
        end

        def region_only?
          true
        end
      end
    end
  end
end
