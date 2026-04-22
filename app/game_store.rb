require 'securerandom'

module Chess
  class GameStore
    TTL = 1800  # 30 minutes idle

    def initialize
      @games    = {}
      @accessed = {}
    end

    def create
      game_id              = SecureRandom.uuid
      @games[game_id]      = Game.new
      @accessed[game_id]   = Time.now
      game_id
    end

    def get(game_id)
      evict_stale
      game = @games[game_id]
      @accessed[game_id] = Time.now if game
      game
    end

    def load(game)
      game_id            = SecureRandom.uuid
      @games[game_id]    = game
      @accessed[game_id] = Time.now
      game_id
    end

    def delete(game_id)
      @games.delete(game_id)
      @accessed.delete(game_id)
    end

    def size
      @games.size
    end

    private

    def evict_stale
      cutoff = Time.now - TTL
      @accessed.each do |id, time|
        next if time >= cutoff
        @games.delete(id)
        @accessed.delete(id)
      end
    end
  end
end
