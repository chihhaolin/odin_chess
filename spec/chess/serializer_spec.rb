require 'tmpdir'

RSpec.describe Chess::Serializer do
  let(:game) { Chess::Game.new }
  let(:tmpdir) { Dir.mktmpdir }
  let(:save_path) { File.join(tmpdir, 'test_save.yml') }

  after { FileUtils.rm_rf(tmpdir) }

  def make(from_str, to_str, **opts)
    f = from_str; t = to_str
    Chess::Move.new(
      from: [f[1].to_i - 1, f[0].ord - 'a'.ord],
      to:   [t[1].to_i - 1, t[0].ord - 'a'.ord],
      **opts
    )
  end

  describe '.save' do
    it 'creates a file at the given path' do
      described_class.save(game, save_path)
      expect(File.exist?(save_path)).to be true
    end

    it 'writes YAML content' do
      described_class.save(game, save_path)
      content = File.read(save_path)
      expect(content).to start_with('---')
    end
  end

  describe '.load' do
    it 'restores current_turn' do
      game.make_move(make('e2', 'e4'))
      described_class.save(game, save_path)
      loaded = described_class.load(save_path)
      expect(loaded.current_turn).to eq :black
    end

    it 'restores piece positions' do
      game.make_move(make('e2', 'e4'))
      described_class.save(game, save_path)
      loaded = described_class.load(save_path)
      expect(loaded.board.piece_at([3, 4])).to be_a Chess::Pieces::Pawn
      expect(loaded.board.piece_at([1, 4])).to be_nil
    end

    it 'restores move history' do
      m = make('e2', 'e4')
      game.make_move(m)
      described_class.save(game, save_path)
      loaded = described_class.load(save_path)
      expect(loaded.move_history.size).to eq 1
      expect(loaded.move_history.first.from).to eq [1, 4]
      expect(loaded.move_history.first.to).to eq [3, 4]
    end

    it 'restores the moved flag on pieces' do
      game.make_move(make('e2', 'e4'))
      described_class.save(game, save_path)
      loaded = described_class.load(save_path)
      moved_pawn = loaded.board.piece_at([3, 4])
      expect(moved_pawn.moved?).to be true
    end

    it 'restores en_passant_target' do
      game.make_move(make('e2', 'e4'))
      described_class.save(game, save_path)
      loaded = described_class.load(save_path)
      expect(loaded.board.en_passant_target).to eq [2, 4]
    end

    it 'restores castling rights (king not moved flag)' do
      described_class.save(game, save_path)
      loaded = described_class.load(save_path)
      white_king = loaded.board.piece_at([0, 4])
      expect(white_king.moved?).to be false
    end

    it 'restores the game status' do
      described_class.save(game, save_path)
      loaded = described_class.load(save_path)
      expect(loaded.status).to eq :playing
    end
  end

  describe 'round-trip with multiple moves' do
    it 'preserves the full game state after several moves' do
      game.make_move(make('e2', 'e4'))
      game.make_move(make('e7', 'e5'))
      game.make_move(make('d2', 'd4'))
      described_class.save(game, save_path)
      loaded = described_class.load(save_path)

      expect(loaded.current_turn).to eq :black
      expect(loaded.move_history.size).to eq 3
      expect(loaded.board.piece_at([3, 4])).to be_a Chess::Pieces::Pawn  # e4
      expect(loaded.board.piece_at([4, 4])).to be_a Chess::Pieces::Pawn  # e5
      expect(loaded.board.piece_at([3, 3])).to be_a Chess::Pieces::Pawn  # d4
    end
  end

  describe 'round-trip with promotion' do
    it 'preserves a promoted queen' do
      game.board.grid.map! { Array.new(8, nil) }
      game.board.place(Chess::Pieces::King.new(:white, [0, 4]), [0, 4])
      game.board.place(Chess::Pieces::King.new(:black, [7, 4]), [7, 4])
      pawn = Chess::Pieces::Pawn.new(:white, [6, 0])
      game.board.place(pawn, [6, 0])
      game.instance_variable_set(:@current_turn, :white)

      game.make_move(Chess::Move.new(from: [6, 0], to: [7, 0],
                                    type: :promotion, promotion_piece: :queen))
      described_class.save(game, save_path)
      loaded = described_class.load(save_path)
      expect(loaded.board.piece_at([7, 0])).to be_a Chess::Pieces::Queen
    end
  end
end
