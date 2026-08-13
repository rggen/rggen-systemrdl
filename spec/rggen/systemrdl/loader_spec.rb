# frozen_string_literal: true

RSpec.describe RgGen::SystemRDL::Loader do
  it "supports 'rdl' file type" do
    loader = described_class.new([], [])

    expect(loader.support?('foo.rdl')).to be true
    expect(loader.support?('foo.yaml')).to be false
    expect(loader.support?('foo.json')).to be false
    expect(loader.support?('foo.toml')).to be false
  end
end
