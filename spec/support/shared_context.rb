# frozen_string_literal: true

RSpec.shared_context 'systemrdl common' do
  include_context 'configuration common'

  let(:filename) do
    'test.rdl'
  end

  def load_rdl(rdl, layer, **cfg_values)
    factory = RgGen.builder.build_factory(:input, :register_map)

    cfg =
      if cfg_values.empty?
        create_configuration(ignore_precedence: true)
      else
        create_configuration(**cfg_values)
      end
    input_data = factory.__send__(:create_input_data, cfg)
    valid_value_lists = factory.__send__(:valid_value_lists)
    loader = factory.loaders.find { |l| l.support?(filename) }

    setup_rdl_file(rdl)
    loader.load_file(input_data, valid_value_lists, filename)

    collect_layer_data(input_data, layer)
  end

  def setup_rdl_file(rdl)
    allow(File).to receive(:readable?).with(filename).and_return(true)
    allow(File).to receive(:open).with(filename).and_yield(StringIO.new(+rdl))
  end

  def collect_layer_data(input_data, layer)
    data = []
    data << input_data if input_data.layer == layer
    input_data.children.each do |child|
      data.concat(collect_layer_data(child, layer))
    end

    data
  end
end
