RSpec.describe(MB::EQLoader::PEQ) do
  let(:io) { nil }
  let(:peq) { described_class.new(node: 0x1000, object: 0x100, io: io) }

  it 'can be constructed' do
    expect(described_class.new(node: 0x1234, object: 0x100)).to respond_to(:set_bypass_all)
  end

  describe '#set_band' do
    let(:io) { StringIO.new('') }
    it 'generates a message for each parameter on a band' do
      expect(io).to receive(:write).exactly(6).times
      expect(peq.set_band(band: 3, bypass: false, frequency: 500, gain: 3, width: 0.25, type: :bell, slope: 0).length).to eq(6)
    end
  end
end
