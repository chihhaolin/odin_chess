RSpec.describe Chess::MoveValidator do
  subject(:validator) { described_class.new }
  let(:board)         { Chess::Board.new }

  # ── helpers ────────────────────────────────────────────────────────────────
  def place(klass, color, pos)
    piece = klass.new(color, pos)
    board.place(piece, pos)
    piece
  end

  def move(from, to, type: :normal, promotion_piece: nil)
    Chess::Move.new(from: from, to: to, type: type, promotion_piece: promotion_piece)
  end

  # ══ in_check? ══════════════════════════════════════════════════════════════
  describe '#in_check?' do
    it 'returns false on an empty board (no king)' do
      expect(validator.in_check?(:white, board)).to be false
    end

    it 'returns false when king is safe' do
      place(Chess::Pieces::King, :white, [0, 4])
      place(Chess::Pieces::Rook, :black, [7, 0])
      expect(validator.in_check?(:white, board)).to be false
    end

    it 'detects check from an enemy rook on the same rank' do
      place(Chess::Pieces::King, :white, [0, 4])
      place(Chess::Pieces::Rook, :black, [0, 7])
      expect(validator.in_check?(:white, board)).to be true
    end

    it 'detects check from an enemy rook on the same file' do
      place(Chess::Pieces::King, :white, [3, 4])
      place(Chess::Pieces::Rook, :black, [7, 4])
      expect(validator.in_check?(:white, board)).to be true
    end

    it 'does not flag check when rook is blocked by a piece' do
      place(Chess::Pieces::King,   :white, [0, 4])
      place(Chess::Pieces::Pawn,   :white, [0, 6])
      place(Chess::Pieces::Rook,   :black, [0, 7])
      expect(validator.in_check?(:white, board)).to be false
    end

    it 'detects check from an enemy bishop on a diagonal' do
      place(Chess::Pieces::King,   :white, [0, 4])
      place(Chess::Pieces::Bishop, :black, [4, 0])
      expect(validator.in_check?(:white, board)).to be true
    end

    it 'detects check from an enemy queen (diagonal)' do
      place(Chess::Pieces::King,  :white, [0, 4])
      place(Chess::Pieces::Queen, :black, [3, 7])
      expect(validator.in_check?(:white, board)).to be true
    end

    it 'detects check from an enemy knight' do
      place(Chess::Pieces::King,   :white, [3, 4])
      place(Chess::Pieces::Knight, :black, [1, 3])
      expect(validator.in_check?(:white, board)).to be true
    end

    it 'detects check from an enemy pawn (diagonal attack)' do
      place(Chess::Pieces::King, :white, [3, 4])
      place(Chess::Pieces::Pawn, :black, [4, 5])
      expect(validator.in_check?(:white, board)).to be true
    end

    it 'does not flag pawn attack on the same file' do
      place(Chess::Pieces::King, :white, [3, 4])
      place(Chess::Pieces::Pawn, :black, [4, 4])
      expect(validator.in_check?(:white, board)).to be false
    end

    it 'detects check for black' do
      place(Chess::Pieces::King,  :black, [7, 4])
      place(Chess::Pieces::Queen, :white, [4, 4])
      expect(validator.in_check?(:black, board)).to be true
    end
  end

  # ══ legal_moves ════════════════════════════════════════════════════════════
  describe '#legal_moves' do
    it 'excludes moves that leave the king in check' do
      # King on e1, Rook on e5 (pinned rook scenario via queen)
      place(Chess::Pieces::King, :white, [0, 4])
      rook = place(Chess::Pieces::Rook, :white, [3, 4])
      place(Chess::Pieces::Rook, :black, [7, 4])
      # White rook on e4 is pinned – moving it would expose king on e1
      legal = validator.legal_moves(:white, board)
      rook_moves = legal.select { |m| m.from == [3, 4] }
      # Rook can only move along file 4 (the pin line), not left/right
      rook_moves.each { |m| expect(m.to[1]).to eq 4 }
    end

    it 'allows king to move away from check' do
      place(Chess::Pieces::King, :white, [0, 4])
      place(Chess::Pieces::Rook, :black, [0, 7])
      legal = validator.legal_moves(:white, board)
      king_moves = legal.select { |m| m.from == [0, 4] }
      expect(king_moves).not_to be_empty
      # King must not move to any square still on rank 0 (rook's rank)
      king_moves.each { |m| expect(m.to[0]).not_to eq 0 }
    end

    it 'allows interposing to block a check' do
      place(Chess::Pieces::King, :white, [0, 4])
      place(Chess::Pieces::Rook, :white, [5, 5])   # can slide to [0,5] to block
      place(Chess::Pieces::Rook, :black, [0, 7])
      legal = validator.legal_moves(:white, board)
      interpose = legal.find { |m| m.from == [5, 5] && m.to == [0, 5] }
      expect(interpose).not_to be_nil
    end

    it 'allows capturing the checking piece' do
      place(Chess::Pieces::King,  :white, [0, 4])
      place(Chess::Pieces::Queen, :black, [0, 7])
      place(Chess::Pieces::Rook,  :white, [3, 7])
      legal = validator.legal_moves(:white, board)
      capture = legal.find { |m| m.from == [3, 7] && m.to == [0, 7] }
      expect(capture).not_to be_nil
    end
  end

  # ══ Castling validation ════════════════════════════════════════════════════
  describe '#legal_moves – castling' do
    let(:king)    { Chess::Pieces::King.new(:white, [0, 4]) }
    let(:ks_rook) { Chess::Pieces::Rook.new(:white, [0, 7]) }
    let(:qs_rook) { Chess::Pieces::Rook.new(:white, [0, 0]) }

    before do
      board.place(king,    [0, 4])
      board.place(ks_rook, [0, 7])
      board.place(qs_rook, [0, 0])
    end

    it 'includes kingside castling when safe' do
      legal_tos = validator.legal_moves(:white, board).map(&:to)
      expect(legal_tos).to include([0, 6])
    end

    it 'includes queenside castling when safe' do
      legal_tos = validator.legal_moves(:white, board).map(&:to)
      expect(legal_tos).to include([0, 2])
    end

    it 'excludes castling when king is in check' do
      place(Chess::Pieces::Rook, :black, [0, 5])
      legal_types = validator.legal_moves(:white, board).map(&:type)
      expect(legal_types).not_to include(:castle_kingside)
      expect(legal_types).not_to include(:castle_queenside)
    end

    it 'excludes kingside castling when king would pass through an attacked square' do
      # Enemy rook attacks f1 [0,5] – the passing square
      place(Chess::Pieces::Rook, :black, [7, 5])
      legal_types = validator.legal_moves(:white, board).map(&:type)
      expect(legal_types).not_to include(:castle_kingside)
    end

    it 'excludes queenside castling when king would pass through an attacked square' do
      # Enemy rook attacks d1 [0,3] – the passing square
      place(Chess::Pieces::Rook, :black, [7, 3])
      legal_types = validator.legal_moves(:white, board).map(&:type)
      expect(legal_types).not_to include(:castle_queenside)
    end

    it 'excludes castling when destination square is attacked (covered by safe_after_move check)' do
      place(Chess::Pieces::Rook, :black, [7, 6])
      legal_types = validator.legal_moves(:white, board).map(&:type)
      expect(legal_types).not_to include(:castle_kingside)
    end
  end

  # ══ apply_move! ════════════════════════════════════════════════════════════
  describe '#apply_move!' do
    it 'applies a normal move' do
      pawn = place(Chess::Pieces::Pawn, :white, [1, 4])
      validator.apply_move!(board, move([1, 4], [3, 4]))
      expect(board.piece_at([3, 4])).to be pawn
      expect(board.piece_at([1, 4])).to be_nil
    end

    it 'sets en_passant_target after a double pawn push' do
      place(Chess::Pieces::Pawn, :white, [1, 4])
      validator.apply_move!(board, move([1, 4], [3, 4]))
      expect(board.en_passant_target).to eq [2, 4]
    end

    it 'clears en_passant_target after a non-double-push move' do
      board.en_passant_target = [2, 4]
      place(Chess::Pieces::Pawn, :white, [3, 4])
      validator.apply_move!(board, move([3, 4], [4, 4]))
      expect(board.en_passant_target).to be_nil
    end

    it 'applies en passant and removes the captured pawn' do
      place(Chess::Pieces::Pawn, :white, [4, 3])
      place(Chess::Pieces::Pawn, :black, [4, 4])
      board.en_passant_target = [5, 4]
      validator.apply_move!(board, move([4, 3], [5, 4], type: :en_passant))
      expect(board.piece_at([5, 4])).to be_a Chess::Pieces::Pawn
      expect(board.piece_at([4, 4])).to be_nil
    end

    it 'applies kingside castling (king and rook move correctly)' do
      king = place(Chess::Pieces::King, :white, [0, 4])
      rook = place(Chess::Pieces::Rook, :white, [0, 7])
      validator.apply_move!(board, move([0, 4], [0, 6], type: :castle_kingside))
      expect(board.piece_at([0, 6])).to be king
      expect(board.piece_at([0, 5])).to be rook
      expect(board.piece_at([0, 4])).to be_nil
      expect(board.piece_at([0, 7])).to be_nil
    end

    it 'applies queenside castling (king and rook move correctly)' do
      king = place(Chess::Pieces::King, :white, [0, 4])
      rook = place(Chess::Pieces::Rook, :white, [0, 0])
      validator.apply_move!(board, move([0, 4], [0, 2], type: :castle_queenside))
      expect(board.piece_at([0, 2])).to be king
      expect(board.piece_at([0, 3])).to be rook
      expect(board.piece_at([0, 4])).to be_nil
      expect(board.piece_at([0, 0])).to be_nil
    end

    it 'applies a promotion and replaces the pawn with the chosen piece' do
      place(Chess::Pieces::Pawn, :white, [6, 4])
      validator.apply_move!(board, move([6, 4], [7, 4], type: :promotion, promotion_piece: :queen))
      promoted = board.piece_at([7, 4])
      expect(promoted).to be_a Chess::Pieces::Queen
      expect(promoted.color).to eq :white
    end

    it 'defaults to queen when promotion_piece is nil' do
      place(Chess::Pieces::Pawn, :white, [6, 4])
      validator.apply_move!(board, move([6, 4], [7, 4], type: :promotion, promotion_piece: nil))
      expect(board.piece_at([7, 4])).to be_a Chess::Pieces::Queen
    end
  end

  # ══ checkmate? ═════════════════════════════════════════════════════════════
  describe '#checkmate?' do
    it 'returns false when the position is not checkmate' do
      place(Chess::Pieces::King, :white, [0, 4])
      place(Chess::Pieces::King, :black, [7, 4])
      expect(validator.checkmate?(:white, board)).to be false
    end

    it 'detects back-rank checkmate' do
      # White king h1 [0,7], Black queen g2 [1,6], Black king f3 [2,5]
      place(Chess::Pieces::King,  :white, [0, 7])
      place(Chess::Pieces::Queen, :black, [1, 6])
      place(Chess::Pieces::King,  :black, [2, 5])
      expect(validator.checkmate?(:white, board)).to be true
    end

    it 'is not checkmate when king can escape' do
      place(Chess::Pieces::King,  :white, [0, 4])
      place(Chess::Pieces::Rook,  :black, [0, 7])
      expect(validator.checkmate?(:white, board)).to be false
    end
  end

  # ══ stalemate? ═════════════════════════════════════════════════════════════
  describe '#stalemate?' do
    it 'returns false when the player has legal moves' do
      place(Chess::Pieces::King, :white, [0, 4])
      expect(validator.stalemate?(:white, board)).to be false
    end

    it 'returns false when the player is in check (that is checkmate, not stalemate)' do
      place(Chess::Pieces::King,  :white, [0, 7])
      place(Chess::Pieces::Queen, :black, [1, 6])
      place(Chess::Pieces::King,  :black, [2, 5])
      expect(validator.stalemate?(:white, board)).to be false
    end

    it 'detects stalemate (classic corner stalemate)' do
      # White king a1 [0,0], Black queen b3 [2,1], Black king c2 [1,2]
      place(Chess::Pieces::King,  :white, [0, 0])
      place(Chess::Pieces::Queen, :black, [2, 1])
      place(Chess::Pieces::King,  :black, [1, 2])
      expect(validator.stalemate?(:white, board)).to be true
    end
  end
end
