# frozen_string_literal: true

describe Facter::Resolvers::Aix::Disks do
  subject(:resolver) { Facter::Resolvers::Aix::Disks }

  before do
    allow(Facter::Core::Execution).to receive(:execute)
      .with('lspv', logger: an_instance_of(Facter::Log))
      .and_return(result)
  end

  after do
    resolver.invalidate_cache
  end

  context 'when retrieving disks name fails' do
    let(:result) { '' }

    it 'returns nil' do
      expect(resolver.resolve(:disks)).to be_nil
    end
  end

  context 'when lspv is successful' do
    let(:result) { load_fixture('lspv_output').read }

    let(:disks) do
      { 'hdisk0' => { size: '29.97 GiB', size_bytes: 32_178_700_288 } }
    end

    before do
      allow(Facter::Core::Execution).to receive(:execute)
        .with('lspv hdisk0', logger: an_instance_of(Facter::Log))
        .and_return(load_fixture('lspv_disk_output').read)
    end

    it 'returns disks informations' do
      expect(resolver.resolve(:disks)).to eql(disks)
    end

    context 'when second lspv call fails' do
      before do
        allow(Facter::Core::Execution).to receive(:execute)
          .with('lspv hdisk0', logger: an_instance_of(Facter::Log))
          .and_return('')
      end

      it 'returns disks informations' do
        expect(resolver.resolve(:disks)).to eq({})
      end
    end
  end
end
