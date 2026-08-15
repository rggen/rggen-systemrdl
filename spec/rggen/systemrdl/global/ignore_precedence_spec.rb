# frozen_string_literal: true

RSpec.describe 'global/ignore_precedence' do
  include_context 'configuration common'

  describe '#ignore_precedence?' do
    specify 'the default value is false' do
      configuration = create_configuration
      expect(configuration).to have_property(:ignore_precedence?, false)
    end

    context 'when precedence is ignored' do
      it 'returns true' do
        configuration = create_configuration(ignore_precedence: true)
        expect(configuration).to have_property(:ignore_precedence?, true)

        [/true/i, /yes/i, /on/i].each do |pattern|
          value = random_string(pattern)
          configuration = create_configuration(ignore_precedence: value)
          expect(configuration).to have_property(:ignore_precedence?, true)

          value = random_string(pattern).to_sym
          configuration = create_configuration(ignore_precedence: value)
          expect(configuration).to have_property(:ignore_precedence?, true)
        end
      end
    end

    context 'when precedence is not ignored' do
      it 'returns false' do
        configuration = create_configuration(ignore_precedence: false)
        expect(configuration).to have_property(:ignore_precedence?, false)

        [/false/i, /no/i, /off/i].each do |pattern|
          value = random_string(pattern)
          configuration = create_configuration(ignore_precedence: value)
          expect(configuration).to have_property(:ignore_precedence?, false)

          value = random_string(pattern).to_sym
          configuration = create_configuration(ignore_precedence: value)
          expect(configuration).to have_property(:ignore_precedence?, false)
        end
      end
    end
  end

  it 'returns the configured value as a printable object' do
    configuration = create_configuration(ignore_precedence: true)
    expect(configuration.printables[:ignore_precedence]).to be true

    configuration = create_configuration(ignore_precedence: false)
    expect(configuration.printables[:ignore_precedence]).to be false
  end

  describe 'error check' do
    context 'when a value other than true/yes/on/false/no/off is given' do
      it 'raises a SourceError' do
        [nil, '', 'foo', :foo, 0, 1, Object.new].each do |value|
          expect {
            create_configuration(ignore_precedence: value)
          }.to raise_source_error "cannot convert #{value.inspect} into boolean"
        end
      end
    end
  end
end
