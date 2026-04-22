require 'spec_helper'
require 'app/game_store'

RSpec.describe Chess::GameStore do
  subject(:store) { described_class.new }

  describe '#create' do
    it 'returns a UUID-format string' do
      id = store.create
      expect(id).to match(/\A[0-9a-f\-]{36}\z/)
    end

    it 'initializes a new Chess::Game' do
      id = store.create
      expect(store.get(id)).to be_a(Chess::Game)
    end

    it 'increments size' do
      expect { store.create }.to change { store.size }.by(1)
    end
  end

  describe '#get' do
    it 'returns the game for a known id' do
      id = store.create
      expect(store.get(id)).to be_a(Chess::Game)
    end

    it 'returns nil for an unknown id' do
      expect(store.get('no-such-id')).to be_nil
    end

    it 'updates the last-accessed timestamp' do
      id = store.create
      store.instance_variable_get(:@accessed)[id] = Time.now - 60
      store.get(id)
      expect(store.instance_variable_get(:@accessed)[id]).to be > Time.now - 5
    end
  end

  describe '#load' do
    it 'returns a new UUID for the injected game' do
      game = Chess::Game.new
      id   = store.load(game)
      expect(id).to match(/\A[0-9a-f\-]{36}\z/)
    end

    it 'makes the injected game accessible via the returned id' do
      game = Chess::Game.new
      id   = store.load(game)
      expect(store.get(id)).to be(game)
    end
  end

  describe '#delete' do
    it 'removes the game from the store' do
      id = store.create
      store.delete(id)
      expect(store.get(id)).to be_nil
    end

    it 'decrements size' do
      id = store.create
      expect { store.delete(id) }.to change { store.size }.by(-1)
    end
  end

  describe '#size' do
    it 'returns the number of stored games' do
      3.times { store.create }
      expect(store.size).to eq(3)
    end
  end

  describe 'TTL eviction' do
    it 'evicts a game whose last-access is older than TTL' do
      id = store.create
      store.instance_variable_get(:@accessed)[id] = Time.now - (Chess::GameStore::TTL + 1)
      expect(store.get(id)).to be_nil
    end

    it 'does not evict a recently accessed game' do
      id = store.create
      expect(store.get(id)).not_to be_nil
    end
  end
end
