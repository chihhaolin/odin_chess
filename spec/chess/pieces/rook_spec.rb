RSpec.describe Chess::Pieces::Rook do
  let(:board) { Chess::Board.new }
  let(:rook)  { described_class.new(:white, [3, 3]) }
  before      { board.place(rook, [3, 3]) }

  def destinations = rook.moves(board).map(&:to)

  describe '#moves – orthogonal sliding' do
    it 'moves along the entire rank' do
      (0..7).reject { |f| f == 3 }.each { |f| expect(destinations).to include([3, f]) }
    end

    it 'moves along the entire file' do
      (0..7).reject { |r| r == 3 }.each { |r| expect(destinations).to include([r, 3]) }
    end

    it 'does not move diagonally' do
      expect(destinations).not_to include([4, 4])
      expect(destinations).not_to include([2, 2])
    end

    it 'generates exactly 14 moves on an otherwise empty board' do
      expect(rook.moves(board).size).to eq 14
    end
  end

  describe '#moves – blocking' do
    it 'is blocked by a friendly piece and cannot land on it' do
      board.place(Chess::Pieces::Pawn.new(:white, [3, 5]), [3, 5])
      expect(destinations).to include([3, 4])
      expect(destinations).not_to include([3, 5])
      expect(destinations).not_to include([3, 6])
    end

    it 'is blocked by an enemy piece and can capture it but not go further' do
      board.place(Chess::Pieces::Pawn.new(:black, [3, 5]), [3, 5])
      expect(destinations).to include([3, 5])
      expect(destinations).not_to include([3, 6])
    end
  end

  describe '#symbol' do
    it 'returns ♖ for white' do
      expect(described_class.new(:white, [0, 0]).symbol).to eq '♖'
    end

    it 'returns ♜ for black' do
      expect(described_class.new(:black, [7, 0]).symbol).to eq '♜'
    end
  end
end
