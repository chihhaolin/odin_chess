RSpec.describe Chess::Pieces::Queen do
  let(:board) { Chess::Board.new }
  let(:queen) { described_class.new(:white, [3, 3]) }
  before      { board.place(queen, [3, 3]) }

  def destinations = queen.moves(board).map(&:to)

  describe '#moves – sliding in all 8 directions' do
    it 'can reach all squares along its rank' do
      (0..7).reject { |f| f == 3 }.each { |f| expect(destinations).to include([3, f]) }
    end

    it 'can reach all squares along its file' do
      (0..7).reject { |r| r == 3 }.each { |r| expect(destinations).to include([r, 3]) }
    end

    it 'can reach squares along both diagonals' do
      expect(destinations).to include([0, 0], [7, 7], [0, 6], [6, 0])
    end
  end

  describe '#moves – blocked by friendly pieces' do
    it 'cannot pass through or land on a friendly piece' do
      board.place(Chess::Pieces::Pawn.new(:white, [3, 5]), [3, 5])
      # Can reach [3,4] but not [3,5] or [3,6]
      expect(destinations).to include([3, 4])
      expect(destinations).not_to include([3, 5])
      expect(destinations).not_to include([3, 6])
    end
  end

  describe '#moves – capture' do
    it 'can capture an enemy piece and stops there' do
      board.place(Chess::Pieces::Rook.new(:black, [3, 6]), [3, 6])
      expect(destinations).to include([3, 6])
      expect(destinations).not_to include([3, 7])
    end

    it 'can capture diagonally' do
      board.place(Chess::Pieces::Pawn.new(:black, [5, 5]), [5, 5])
      expect(destinations).to include([5, 5])
      expect(destinations).not_to include([6, 6])
    end
  end

  describe '#moves – corner position' do
    it 'from a1 [0,0] only moves along rank 0, file a, and one diagonal' do
      fresh_board  = Chess::Board.new
      corner_queen = described_class.new(:white, [0, 0])
      fresh_board.place(corner_queen, [0, 0])
      dests = corner_queen.moves(fresh_board).map(&:to)
      expect(dests).to include([0, 7], [7, 0], [7, 7])
    end
  end

  describe '#symbol' do
    it 'returns ♕ for white' do
      expect(described_class.new(:white, [0, 3]).symbol).to eq '♕'
    end

    it 'returns ♛ for black' do
      expect(described_class.new(:black, [7, 3]).symbol).to eq '♛'
    end
  end
end
