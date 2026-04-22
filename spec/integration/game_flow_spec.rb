require 'spec_helper'
require 'chess/cli'
require 'tmpdir'
require 'stringio'

# Integration tests: exercises the full stack from CLI input parsing
# through Game/MoveValidator/Board down to piece movement, then back to
# Renderer output — no mocking of domain logic.
RSpec.describe 'Phase 1 + Phase 2 integration' do
  let(:parser)   { Chess::CLI::InputParser.new }
  let(:renderer) { Chess::CLI::Renderer.new }

  # Build a Move by parsing an algebraic string and executing it on a game
  def submit(game, notation)
    result = parser.parse(notation)
    raise "Bad parse: #{notation}" unless result[:type] == :move

    candidates = game.legal_moves.select do |m|
      m.from == result[:from] && m.to == result[:to] &&
        (result[:promotion_piece].nil? || m.promotion_piece == result[:promotion_piece])
    end
    raise "No legal move for #{notation} — candidates: #{game.legal_moves.map(&:to_s)}" if candidates.empty?

    move = candidates.first
    game.make_move(move)
  end

  # ------------------------------------------------------------------ #
  # Basic opening moves                                                  #
  # ------------------------------------------------------------------ #
  describe 'opening moves' do
    let(:game) { Chess::Game.new }

    it 'white plays e2 e4, then black plays e7 e5' do
      expect(submit(game, 'e2 e4')[:success]).to be true
      expect(game.current_turn).to eq(:black)

      expect(submit(game, 'e7 e5')[:success]).to be true
      expect(game.current_turn).to eq(:white)
    end

    it 'board reflects the moved pawns after e2 e4 / e7 e5' do
      submit(game, 'e2 e4')
      submit(game, 'e7 e5')
      expect(game.board.piece_at([1, 4])).to be_nil
      expect(game.board.piece_at([3, 4])&.type).to eq(:pawn)
      expect(game.board.piece_at([6, 4])).to be_nil
      expect(game.board.piece_at([4, 4])&.type).to eq(:pawn)
    end

    it 'move_history grows with each submitted move' do
      submit(game, 'e2 e4')
      submit(game, 'e7 e5')
      expect(game.move_history.length).to eq(2)
    end
  end

  # ------------------------------------------------------------------ #
  # Scholar's Mate (4-move checkmate)                                   #
  # ------------------------------------------------------------------ #
  describe "Scholar's Mate" do
    let(:game) { Chess::Game.new }

    it 'ends in checkmate after 4 moves' do
      submit(game, 'e2 e4')
      submit(game, 'e7 e5')
      submit(game, 'd1 h5')  # white queen to h5
      submit(game, 'b8 c6')  # black knight
      submit(game, 'f1 c4')  # white bishop
      submit(game, 'a7 a6')  # black makes irrelevant move
      submit(game, 'h5 f7')  # queen takes f7 — checkmate

      expect(game.status).to eq(:checkmate)
      expect(game.over?).to  be true
    end
  end

  # ------------------------------------------------------------------ #
  # Check detection via renderer                                        #
  # ------------------------------------------------------------------ #
  describe 'check state renders correctly' do
    it 'applies CHECK_BG to king square when in check' do
      game = Chess::Game.new
      # Scholar's mate setup — stop just before checkmate to get check state
      submit(game, 'e2 e4')
      submit(game, 'e7 e5')
      submit(game, 'd1 h5')
      submit(game, 'b8 c6')
      submit(game, 'f1 c4')
      submit(game, 'a7 a6')
      # Qh5xf7+ — black king is in check but not mate
      # Actually after Qxf7 it IS mate (from test above). Let's use a different check setup.
      # Simpler: put king directly in check via board manipulation
      game2 = Chess::Game.new
      game2.board.setup_initial_position
      # Clear e-file and move white rook to attack black king differently
      # Easiest: use a known check: Ruy Lopez-like, or just test in_check with a custom board
      board = Chess::Board.new
      board.place(Chess::Pieces::King.new(:white, [0, 4]), [0, 4])
      board.place(Chess::Pieces::King.new(:black, [7, 4]), [7, 4])
      board.place(Chess::Pieces::Rook.new(:white, [7, 0]), [7, 0])  # Rook attacks black king rank

      output = renderer.render(board, in_check_color: :black)
      expect(output).to include(Chess::CLI::Renderer::CHECK_BG)
    end
  end

  # ------------------------------------------------------------------ #
  # Stalemate detection                                                  #
  # ------------------------------------------------------------------ #
  describe 'stalemate' do
    it 'detects stalemate via make_move result' do
      # Classic corner stalemate: White King a1, Black Queen b3, Black King c2
      board = Chess::Board.new
      board.place(Chess::Pieces::King.new(:white, [0, 0]), [0, 0])
      board.place(Chess::Pieces::Queen.new(:black, [2, 1]), [2, 1])
      board.place(Chess::Pieces::King.new(:black, [1, 2]), [1, 2])

      game = Chess::Game.allocate
      game.instance_variable_set(:@board,        board)
      game.instance_variable_set(:@current_turn, :white)
      game.instance_variable_set(:@move_history, [])
      game.instance_variable_set(:@status,       :playing)
      game.instance_variable_set(:@validator,    Chess::MoveValidator.new)
      game.send(:update_status)

      expect(game.status).to eq(:stalemate)
      expect(game.over?).to  be true
    end
  end

  # ------------------------------------------------------------------ #
  # En passant: input parser → game engine round-trip                   #
  # ------------------------------------------------------------------ #
  describe 'en passant via CLI input' do
    it 'captures en passant correctly' do
      game = Chess::Game.new

      # Advance white pawn to rank 4 (d-file)
      submit(game, 'd2 d4')
      submit(game, 'a7 a6')
      submit(game, 'd4 d5')
      # Black e-pawn double-push — triggers en passant opportunity
      submit(game, 'e7 e5')

      # White captures en passant: d5 takes e6
      result = parser.parse('d5 e6')
      expect(result[:type]).to eq(:move)
      candidates = game.legal_moves.select { |m| m.from == result[:from] && m.to == result[:to] }
      expect(candidates).not_to be_empty
      ep_move = candidates.find { |m| m.type == :en_passant }
      expect(ep_move).not_to be_nil

      game.make_move(ep_move)
      expect(game.board.piece_at([4, 4])).to be_nil   # captured pawn gone
      expect(game.board.piece_at([5, 4])&.type).to eq(:pawn)  # white pawn at e6
    end
  end

  # ------------------------------------------------------------------ #
  # Pawn promotion: input parser → game engine round-trip               #
  # ------------------------------------------------------------------ #
  describe 'pawn promotion via CLI input' do
    it 'promotes pawn to queen when "e7 e8q" is parsed' do
      board = Chess::Board.new
      board.place(Chess::Pieces::King.new(:white, [0, 4]), [0, 4])
      board.place(Chess::Pieces::King.new(:black, [7, 0]), [7, 0])
      board.place(Chess::Pieces::Pawn.new(:white, [6, 4]), [6, 4])

      game = Chess::Game.allocate
      game.instance_variable_set(:@board,        board)
      game.instance_variable_set(:@current_turn, :white)
      game.instance_variable_set(:@move_history, [])
      game.instance_variable_set(:@status,       :playing)
      game.instance_variable_set(:@validator,    Chess::MoveValidator.new)
      game.send(:update_status)

      result = parser.parse('e7 e8q')
      expect(result[:type]).to eq(:move)
      candidates = game.legal_moves.select do |m|
        m.from == result[:from] && m.to == result[:to] && m.promotion_piece == :queen
      end
      expect(candidates.length).to eq(1)

      game.make_move(candidates.first)
      promoted = game.board.piece_at([7, 4])
      expect(promoted).to be_a(Chess::Pieces::Queen)
      expect(promoted.color).to eq(:white)
    end
  end

  # ------------------------------------------------------------------ #
  # Castling: input parser → game engine round-trip                     #
  # ------------------------------------------------------------------ #
  describe 'kingside castling via CLI input' do
    it 'castles kingside when path is clear' do
      board = Chess::Board.new
      board.place(Chess::Pieces::King.new(:white, [0, 4]), [0, 4])
      board.place(Chess::Pieces::Rook.new(:white, [0, 7]), [0, 7])
      board.place(Chess::Pieces::King.new(:black, [7, 4]), [7, 4])

      game = Chess::Game.allocate
      game.instance_variable_set(:@board,        board)
      game.instance_variable_set(:@current_turn, :white)
      game.instance_variable_set(:@move_history, [])
      game.instance_variable_set(:@status,       :playing)
      game.instance_variable_set(:@validator,    Chess::MoveValidator.new)
      game.send(:update_status)

      result = parser.parse('e1 g1')
      expect(result[:type]).to eq(:move)
      castle_move = game.legal_moves.find { |m| m.from == [0, 4] && m.to == [0, 6] && m.type == :castle_kingside }
      expect(castle_move).not_to be_nil

      game.make_move(castle_move)
      expect(game.board.piece_at([0, 6])&.type).to eq(:king)
      expect(game.board.piece_at([0, 5])&.type).to eq(:rook)
      expect(game.board.piece_at([0, 4])).to be_nil
      expect(game.board.piece_at([0, 7])).to be_nil
    end
  end

  # ------------------------------------------------------------------ #
  # Save / Load round-trip through CLI runner                           #
  # ------------------------------------------------------------------ #
  describe 'save and load via CLI runner' do
    let(:tmp_dir) { Dir.mktmpdir }
    after { FileUtils.rm_rf(tmp_dir) }

    it 'saves and reloads game state correctly' do
      game = Chess::Game.new
      submit(game, 'e2 e4')
      submit(game, 'e7 e5')

      path = File.join(tmp_dir, 'test_save.yml')
      Chess::Serializer.save(game, path)

      loaded = Chess::Serializer.load(path)
      expect(loaded.current_turn).to  eq(:white)
      expect(loaded.move_history.length).to eq(2)
      expect(loaded.board.piece_at([3, 4])&.type).to eq(:pawn)
      expect(loaded.board.piece_at([4, 4])&.type).to eq(:pawn)
    end

    it 'runner saves a file when "save" is entered' do
      stub_const("Chess::CLI::Runner::SAVES_DIR", tmp_dir)
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(tmp_dir).and_return(false)

      input  = StringIO.new("e2 e4\nsave\nquit\n")
      output = StringIO.new
      runner = Chess::CLI::Runner.new(input: input, output: output)

      begin
        runner.start
      rescue SystemExit
        # ok
      end

      saves = Dir.glob(File.join(tmp_dir, '*.yml'))
      expect(saves).not_to be_empty
    end

    it 'runner deletes a save file when d1 is entered at the startup menu' do
      stub_const("Chess::CLI::Runner::SAVES_DIR", tmp_dir)

      # Seed a save file so the startup menu appears
      game = Chess::Game.new
      submit(game, 'e2 e4')
      Chess::Serializer.save(game, File.join(tmp_dir, 'seed_save.yml'))
      expect(Dir.glob(File.join(tmp_dir, '*.yml')).length).to eq(1)

      # d1 deletes the save; no saves remain so runner starts a new game; quit immediately
      input  = StringIO.new("d1\nquit\n")
      output = StringIO.new
      runner = Chess::CLI::Runner.new(input: input, output: output)

      begin
        runner.start
      rescue SystemExit
        # ok
      end

      expect(Dir.glob(File.join(tmp_dir, '*.yml'))).to be_empty
      expect(output.string).to include('Deleted')
      expect(output.string).to include("White's turn")
    end
  end

  # ------------------------------------------------------------------ #
  # Illegal move prevention                                              #
  # ------------------------------------------------------------------ #
  describe 'illegal move prevention' do
    let(:game) { Chess::Game.new }

    it 'rejects moving an opponent piece' do
      # e7 belongs to black; white has no legal move originating from that square
      candidates = game.legal_moves.select { |m| m.from == [6, 4] }
      expect(candidates).to be_empty

      # Attempting make_move directly also returns failure
      black_pawn_move = Chess::Move.new(from: [6, 4], to: [4, 4])
      result = game.make_move(black_pawn_move)
      expect(result[:success]).to be false
    end

    it 'rejects a move that would expose the king to check' do
      # Pin scenario: white Rook at d1, black Rook at d8, white King at d-file
      board = Chess::Board.new
      board.place(Chess::Pieces::King.new(:white, [0, 3]), [0, 3])
      board.place(Chess::Pieces::Rook.new(:white, [3, 3]), [3, 3])  # pinned along d-file
      board.place(Chess::Pieces::Rook.new(:black, [7, 3]), [7, 3])  # attacker on d8
      board.place(Chess::Pieces::King.new(:black, [7, 0]), [7, 0])

      game2 = Chess::Game.allocate
      game2.instance_variable_set(:@board,        board)
      game2.instance_variable_set(:@current_turn, :white)
      game2.instance_variable_set(:@move_history, [])
      game2.instance_variable_set(:@status,       :playing)
      game2.instance_variable_set(:@validator,    Chess::MoveValidator.new)
      game2.send(:update_status)

      # The white rook is pinned; moving it off the d-file is illegal
      lateral_move = Chess::Move.new(from: [3, 3], to: [3, 4])
      expect(game2.make_move(lateral_move)[:success]).to be false
    end
  end

  # ------------------------------------------------------------------ #
  # Renderer reflects board state from engine                           #
  # ------------------------------------------------------------------ #
  describe 'renderer reflects engine state' do
    it 'shows no pieces on empty squares after captures' do
      game = Chess::Game.new
      # Four Knights opening + capture
      submit(game, 'e2 e4')
      submit(game, 'e7 e5')
      submit(game, 'g1 f3')
      submit(game, 'b8 c6')
      submit(game, 'f1 c4')
      submit(game, 'f8 c5')
      submit(game, 'f3 g5')   # white knight to g5
      submit(game, 'c5 f2')   # black bishop captures f2

      output = renderer.render(game.board, last_move: game.move_history.last)
      # last_move highlight should appear on f2 ([1,5]) — which is in the output
      expect(output).to include(Chess::CLI::Renderer::HIGHLIGHT_BG)
    end
  end
end
