RSpec.describe(MB::EQLoader::ValueTypes) do
  describe '.binary' do
    it 'converts true to 1' do
      expect(described_class.binary(true)).to eq(1).and be_a(Integer)
    end

    it 'converts false to 0' do
      expect(described_class.binary(false)).to eq(0).and be_a(Integer)
    end

    it 'is aliased to .boolean' do
      expect(described_class.boolean(nil)).to eq(0).and be_a(Integer)
    end
  end

  describe '.delay' do
    it 'converts to 96kHz samples' do
      expect(described_class.delay(0.5)).to eq(48000).and be_a(Integer)
    end
  end

  describe '.gain' do
    it 'converts -80dB to approximately -280617' do
      expect(described_class.gain(-80)).to be_between(-280618, -280616).and be_a(Integer)
    end

    it 'converts -11dB to a value greater than -110000 for log scaling' do
      expect(described_class.gain(-11)).to be_between(-109000, -101000).and be_a(Integer)
    end

    it 'converts -10dB to -100000' do
      expect(described_class.gain(-10)).to eq(-100000).and be_a(Integer)
    end

    it 'converts 0dB to 0' do
      expect(described_class.gain(0)).to eq(0).and be_a(Integer)
    end
  end

  describe '.log' do
    it 'converts to scaled logarithmic' do
      expect(described_class.log(100)).to eq(2000000).and be_a(Integer)
      expect(described_class.log(101)).to eq(2004321).and be_a(Integer)
      expect(described_class.log(1000)).to eq(3000000).and be_a(Integer)
    end
  end

  describe '.scalar' do
    it 'scales fractional values up to Integer' do
      expect(described_class.scalar(0.25)).to eq(2500).and be_a(Integer)
    end
  end
end
