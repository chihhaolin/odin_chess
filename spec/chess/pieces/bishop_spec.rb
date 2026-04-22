RSpec.describe Chess::Pieces::Bishop do
  let(:board)  { Chess::Board.new }
  let(:bishop) { described_class.new(:white, [3, 3]) }
  before       { board.place(bishop, [3, 3]) }

  def destinations = bishop.moves(board).map(&:to)

  describe '#moves – diagonal sliding' do
    it 'moves along all four diagonals' do
      expect(destinations).to include([0, 0], [7, 7], [0, 6], [6, 0])
    end

    it 'does not move orthogonally' do
      expect(destinations).not_to include([3, 5])
      expect(destinations).not_to include([5, 3])
    end

    it 'stays on the same color squares' do
      # Bishop at [3,3] is on a dark square (3+3=6 even)
      destinations.each { |r, f| expect((r + f) % 2).to eq((3 + 3) % 2) }
    end
  end

  describe '#moves – blocking' do
    it 'is blocked by a friendly piece' do
      board.place(Chess::Pieces::Pawn.new(:white, [5, 5]), [5, 5])
      expect(destinations).to include([4, 4])
      expect(destinations).not_to include([5, 5])
      expect(destinations).not_to include([6, 6])
    end

    it 'captures an enemy piece and stops' do
      board.place(Chess::Pieces::Pawn.new(:black, [5, 5]), [5, 5])
      expect(destinations).to include([5, 5])
      expect(destinations).not_to include([6, 6])
    end
  end

  describe '#symbol' do
    it 'returns ♗ for white' do
      expect(described_class.new(:white, [0, 2]).symbol).to eq '♗'
    end

    it 'returns ♝ for black' do
      expect(described_class.new(:black, [7, 2]).symbol).to eq '♝'
    end
  end
end
