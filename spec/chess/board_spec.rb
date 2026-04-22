RSpec.describe Chess::Board do
  subject(:board) { described_class.new }

  describe '#piece_at' do
    it 'returns nil on an empty board' do
      expect(board.piece_at([0, 0])).to be_nil
    end

    it 'returns the placed piece' do
      king = Chess::Pieces::King.new(:white, [0, 4])
      board.place(king, [0, 4])
      expect(board.piece_at([0, 4])).to be king
    end
  end

  describe '#place' do
    it 'sets the piece on the grid' do
      rook = Chess::Pieces::Rook.new(:black, [7, 0])
      board.place(rook, [7, 0])
      expect(board.piece_at([7, 0])).to be rook
    end

    it 'updates the piece position attribute' do
      pawn = Chess::Pieces::Pawn.new(:white, [1, 0])
      board.place(pawn, [3, 0])
      expect(pawn.position).to eq [3, 0]
    end

    it 'placing nil clears the square' do
      rook = Chess::Pieces::Rook.new(:white, [0, 0])
      board.place(rook, [0, 0])
      board.place(nil, [0, 0])
      expect(board.piece_at([0, 0])).to be_nil
    end
  end

  describe '#remove' do
    it 'removes and returns the piece' do
      knight = Chess::Pieces::Knight.new(:white, [0, 1])
      board.place(knight, [0, 1])
      removed = board.remove([0, 1])
      expect(removed).to be knight
      expect(board.piece_at([0, 1])).to be_nil
    end

    it 'returns nil when square is already empty' do
      expect(board.remove([3, 3])).to be_nil
    end
  end

  describe '#move_piece' do
    it 'moves the piece to the target square' do
      king = Chess::Pieces::King.new(:white, [0, 4])
      board.place(king, [0, 4])
      board.move_piece([0, 4], [1, 4])
      expect(board.piece_at([1, 4])).to be king
      expect(board.piece_at([0, 4])).to be_nil
    end

    it 'updates the piece position' do
      king = Chess::Pieces::King.new(:white, [0, 4])
      board.place(king, [0, 4])
      board.move_piece([0, 4], [1, 4])
      expect(king.position).to eq [1, 4]
    end

    it 'sets moved flag to true' do
      rook = Chess::Pieces::Rook.new(:white, [0, 0])
      board.place(rook, [0, 0])
      board.move_piece([0, 0], [0, 4])
      expect(rook.moved?).to be true
    end

    it 'overwrites a captured piece on the target square' do
      attacker = Chess::Pieces::Rook.new(:white, [0, 0])
      defender = Chess::Pieces::Rook.new(:black, [0, 7])
      board.place(attacker, [0, 0])
      board.place(defender, [0, 7])
      board.move_piece([0, 0], [0, 7])
      expect(board.piece_at([0, 7])).to be attacker
    end
  end

  describe '#empty?' do
    it 'returns true for an empty square' do
      expect(board.empty?([4, 4])).to be true
    end

    it 'returns false when a piece is present' do
      board.place(Chess::Pieces::Pawn.new(:white, [1, 0]), [1, 0])
      expect(board.empty?([1, 0])).to be false
    end
  end

  describe '#pieces' do
    before { board.setup_initial_position }

    it 'returns all 32 pieces after setup' do
      expect(board.pieces.size).to eq 32
    end

    it 'returns 16 white pieces' do
      expect(board.pieces(:white).size).to eq 16
    end

    it 'returns 16 black pieces' do
      expect(board.pieces(:black).size).to eq 16
    end
  end

  describe '#king_position' do
    it 'returns the position of the king for the given color' do
      board.setup_initial_position
      expect(board.king_position(:white)).to eq [0, 4]
      expect(board.king_position(:black)).to eq [7, 4]
    end

    it 'returns nil when there is no king on the board' do
      expect(board.king_position(:white)).to be_nil
    end
  end

  describe '#deep_clone' do
    it 'produces an independent board' do
      board.setup_initial_position
      clone = board.deep_clone

      board.move_piece([1, 0], [3, 0])
      expect(clone.piece_at([1, 0])).not_to be_nil
    end

    it 'copies the en_passant_target' do
      board.en_passant_target = [2, 4]
      expect(board.deep_clone.en_passant_target).to eq [2, 4]
    end

    it 'mutations to clone do not affect original' do
      board.setup_initial_position
      clone = board.deep_clone
      clone.move_piece([6, 0], [4, 0])
      expect(board.piece_at([6, 0])).not_to be_nil
    end

    it 'copies the moved flag on pieces' do
      rook = Chess::Pieces::Rook.new(:white, [0, 0])
      rook.moved = true
      board.place(rook, [0, 0])
      clone = board.deep_clone
      expect(clone.piece_at([0, 0]).moved?).to be true
    end
  end

  describe '#setup_initial_position' do
    before { board.setup_initial_position }

    it 'places white king at e1' do
      expect(board.piece_at([0, 4])).to be_a Chess::Pieces::King
      expect(board.piece_at([0, 4]).color).to eq :white
    end

    it 'places black king at e8' do
      expect(board.piece_at([7, 4])).to be_a Chess::Pieces::King
      expect(board.piece_at([7, 4]).color).to eq :black
    end

    it 'places white queen at d1' do
      expect(board.piece_at([0, 3])).to be_a Chess::Pieces::Queen
    end

    it 'places white rooks at a1 and h1' do
      expect(board.piece_at([0, 0])).to be_a Chess::Pieces::Rook
      expect(board.piece_at([0, 7])).to be_a Chess::Pieces::Rook
    end

    it 'places 8 white pawns on rank 2' do
      pawns = (0..7).map { |f| board.piece_at([1, f]) }
      expect(pawns.all? { |p| p.is_a?(Chess::Pieces::Pawn) && p.color == :white }).to be true
    end

    it 'places 8 black pawns on rank 7' do
      pawns = (0..7).map { |f| board.piece_at([6, f]) }
      expect(pawns.all? { |p| p.is_a?(Chess::Pieces::Pawn) && p.color == :black }).to be true
    end

    it 'leaves ranks 3–6 empty' do
      (2..5).each do |rank|
        (0..7).each { |file| expect(board.piece_at([rank, file])).to be_nil }
      end
    end

    it 'all pieces start with moved == false' do
      board.pieces.each { |p| expect(p.moved?).to be false }
    end
  end
end
