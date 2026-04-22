RSpec.describe Chess::Pieces::King do
  let(:board)  { Chess::Board.new }
  let(:king)   { described_class.new(:white, [4, 4]) }
  before       { board.place(king, [4, 4]) }

  def destinations(piece = king)
    piece.moves(board).map(&:to)
  end

  describe '#moves – basic movement' do
    it 'can move to all 8 adjacent squares from the centre' do
      expected = [[3,3],[3,4],[3,5],[4,3],[4,5],[5,3],[5,4],[5,5]]
      expect(destinations).to match_array(expected)
    end

    it 'cannot move off the board from a corner (a1 = [0,0])' do
      corner_king = described_class.new(:white, [0, 0])
      board.place(corner_king, [0, 0])
      expect(corner_king.moves(board).map(&:to)).to match_array([[0,1],[1,0],[1,1]])
    end

    it 'cannot move onto a square occupied by a friendly piece' do
      board.place(Chess::Pieces::Pawn.new(:white, [5, 5]), [5, 5])
      expect(destinations).not_to include([5, 5])
    end

    it 'can capture an enemy piece' do
      board.place(Chess::Pieces::Rook.new(:black, [5, 5]), [5, 5])
      expect(destinations).to include([5, 5])
    end

    it 'returns moves of type :normal for regular steps' do
      types = king.moves(board).reject { |m| m.type == :normal }.map(&:type)
      # only castling moves are non-normal
      expect(types).to all(satisfy { |t| %i[castle_kingside castle_queenside].include?(t) })
    end
  end

  describe '#moves – castling' do
    let(:board)      { Chess::Board.new }
    let(:white_king) { described_class.new(:white, [0, 4]) }
    let(:ks_rook)    { Chess::Pieces::Rook.new(:white, [0, 7]) }
    let(:qs_rook)    { Chess::Pieces::Rook.new(:white, [0, 0]) }

    before do
      board.place(white_king, [0, 4])
      board.place(ks_rook,    [0, 7])
      board.place(qs_rook,    [0, 0])
    end

    it 'generates a kingside castling move when path is clear' do
      expect(destinations(white_king)).to include([0, 6])
      move = white_king.moves(board).find { |m| m.to == [0, 6] }
      expect(move.type).to eq :castle_kingside
    end

    it 'generates a queenside castling move when path is clear' do
      expect(destinations(white_king)).to include([0, 2])
      move = white_king.moves(board).find { |m| m.to == [0, 2] }
      expect(move.type).to eq :castle_queenside
    end

    it 'does not generate castling after king has moved' do
      white_king.moved = true
      castle_moves = white_king.moves(board).select { |m| m.type == :castle_kingside || m.type == :castle_queenside }
      expect(castle_moves).to be_empty
    end

    it 'does not generate kingside castling after kingside rook has moved' do
      ks_rook.moved = true
      move_types = white_king.moves(board).map(&:type)
      expect(move_types).not_to include(:castle_kingside)
    end

    it 'does not generate queenside castling after queenside rook has moved' do
      qs_rook.moved = true
      move_types = white_king.moves(board).map(&:type)
      expect(move_types).not_to include(:castle_queenside)
    end

    it 'does not generate kingside castling when f1 is occupied' do
      board.place(Chess::Pieces::Bishop.new(:white, [0, 5]), [0, 5])
      move_types = white_king.moves(board).map(&:type)
      expect(move_types).not_to include(:castle_kingside)
    end

    it 'does not generate kingside castling when g1 is occupied' do
      board.place(Chess::Pieces::Knight.new(:white, [0, 6]), [0, 6])
      move_types = white_king.moves(board).map(&:type)
      expect(move_types).not_to include(:castle_kingside)
    end

    it 'does not generate queenside castling when b1 is occupied' do
      board.place(Chess::Pieces::Knight.new(:white, [0, 1]), [0, 1])
      move_types = white_king.moves(board).map(&:type)
      expect(move_types).not_to include(:castle_queenside)
    end
  end

  describe '#symbol' do
    it 'returns ♔ for white' do
      expect(described_class.new(:white, [0, 4]).symbol).to eq '♔'
    end

    it 'returns ♚ for black' do
      expect(described_class.new(:black, [7, 4]).symbol).to eq '♚'
    end
  end
end
