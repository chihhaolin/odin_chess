RSpec.describe Chess::Pieces::Knight do
  let(:board)  { Chess::Board.new }
  let(:knight) { described_class.new(:white, [3, 3]) }
  before       { board.place(knight, [3, 3]) }

  def destinations(piece = knight) = piece.moves(board).map(&:to)

  describe '#moves – L-shaped movement' do
    it 'has exactly 8 moves from the centre of an empty board' do
      expect(knight.moves(board).size).to eq 8
    end

    it 'reaches all expected L-shaped squares from d4 [3,3]' do
      expected = [[1,2],[1,4],[2,1],[2,5],[4,1],[4,5],[5,2],[5,4]]
      expect(destinations).to match_array(expected)
    end

    it 'has fewer moves from a corner (a1 = [0,0])' do
      corner = described_class.new(:white, [0, 0])
      board.place(corner, [0, 0])
      expect(destinations(corner)).to match_array([[1, 2], [2, 1]])
    end

    it 'has 4 moves from an edge square (a4 = [3,0])' do
      edge = described_class.new(:white, [3, 0])
      board.place(edge, [3, 0])
      expect(destinations(edge)).to match_array([[1,1],[2,2],[4,2],[5,1]])
    end
  end

  describe '#moves – jumping' do
    it 'can jump over pieces' do
      # surround with friendly pieces
      [[2, 2],[2, 3],[2, 4],[3, 2],[3, 4],[4, 2],[4, 3],[4, 4]].each do |pos|
        board.place(Chess::Pieces::Pawn.new(:white, pos), pos)
      end
      expect(knight.moves(board).size).to eq 8
    end
  end

  describe '#moves – captures' do
    it 'can capture an enemy piece on an L-square' do
      board.place(Chess::Pieces::Pawn.new(:black, [5, 4]), [5, 4])
      expect(destinations).to include([5, 4])
    end

    it 'cannot land on a friendly piece' do
      board.place(Chess::Pieces::Pawn.new(:white, [5, 4]), [5, 4])
      expect(destinations).not_to include([5, 4])
    end
  end

  describe '#symbol' do
    it 'returns ♘ for white' do
      expect(described_class.new(:white, [0, 1]).symbol).to eq '♘'
    end

    it 'returns ♞ for black' do
      expect(described_class.new(:black, [7, 1]).symbol).to eq '♞'
    end
  end
end
