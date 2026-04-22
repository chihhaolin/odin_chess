RSpec.describe Chess::Pieces::Pawn do
  let(:board) { Chess::Board.new }

  # ── helpers ────────────────────────────────────────────────────────────────
  def place(type_or_piece, color = nil, pos = nil)
    piece = type_or_piece.is_a?(Chess::Pieces::Piece) ? type_or_piece : type_or_piece.new(color, pos)
    board.place(piece, piece.position)
    piece
  end

  def destinations(pawn) = pawn.moves(board).map(&:to)

  # ══ WHITE PAWN ═════════════════════════════════════════════════════════════
  describe 'white pawn' do
    describe 'forward movement' do
      it 'moves one square forward from any rank' do
        pawn = place(described_class.new(:white, [3, 3]))
        expect(destinations(pawn)).to include([4, 3])
      end

      it 'moves two squares forward from the starting rank (rank 1)' do
        pawn = place(described_class.new(:white, [1, 3]))
        expect(destinations(pawn)).to include([3, 3])
      end

      it 'cannot move two squares when the intermediate square is blocked' do
        pawn = place(described_class.new(:white, [1, 3]))
        place(Chess::Pieces::Pawn.new(:white, [2, 3]))
        expect(destinations(pawn)).not_to include([3, 3])
        expect(destinations(pawn)).not_to include([2, 3])
      end

      it 'cannot move two squares when the destination square is blocked' do
        pawn = place(described_class.new(:white, [1, 3]))
        place(Chess::Pieces::Pawn.new(:black, [3, 3]))
        expect(destinations(pawn)).to include([2, 3])
        expect(destinations(pawn)).not_to include([3, 3])
      end

      it 'cannot move forward when directly blocked' do
        pawn = place(described_class.new(:white, [3, 3]))
        place(Chess::Pieces::Pawn.new(:black, [4, 3]))
        expect(destinations(pawn)).not_to include([4, 3])
      end

      it 'cannot move backward' do
        pawn = place(described_class.new(:white, [3, 3]))
        expect(destinations(pawn)).not_to include([2, 3])
      end
    end

    describe 'diagonal capture' do
      it 'captures diagonally forward when an enemy is present' do
        pawn = place(described_class.new(:white, [3, 3]))
        place(Chess::Pieces::Rook.new(:black, [4, 4]))
        expect(destinations(pawn)).to include([4, 4])
      end

      it 'does not capture forward on the same file' do
        pawn = place(described_class.new(:white, [3, 3]))
        place(Chess::Pieces::Rook.new(:black, [4, 3]))
        capture_moves = pawn.moves(board).select { |m| m.to == [4, 3] }
        expect(capture_moves).to be_empty
      end

      it 'does not move diagonally to an empty square' do
        pawn = place(described_class.new(:white, [3, 3]))
        expect(destinations(pawn)).not_to include([4, 4])
      end

      it 'cannot capture a friendly piece diagonally' do
        pawn = place(described_class.new(:white, [3, 3]))
        place(Chess::Pieces::Pawn.new(:white, [4, 4]))
        expect(destinations(pawn)).not_to include([4, 4])
      end
    end

    describe 'en passant' do
      it 'can capture en passant to the left' do
        pawn = place(described_class.new(:white, [4, 4]))
        board.en_passant_target = [5, 3]
        expect(destinations(pawn)).to include([5, 3])
        expect(pawn.moves(board).find { |m| m.to == [5, 3] }.type).to eq :en_passant
      end

      it 'can capture en passant to the right' do
        pawn = place(described_class.new(:white, [4, 4]))
        board.en_passant_target = [5, 5]
        expect(destinations(pawn)).to include([5, 5])
        expect(pawn.moves(board).find { |m| m.to == [5, 5] }.type).to eq :en_passant
      end

      it 'does not generate en passant when target is not adjacent' do
        pawn = place(described_class.new(:white, [4, 4]))
        board.en_passant_target = [5, 2]
        en_passant = pawn.moves(board).select { |m| m.type == :en_passant }
        expect(en_passant).to be_empty
      end

      it 'does not generate en passant when target is nil' do
        pawn = place(described_class.new(:white, [4, 4]))
        board.en_passant_target = nil
        expect(pawn.moves(board).select { |m| m.type == :en_passant }).to be_empty
      end
    end

    describe 'promotion' do
      it 'generates 4 promotion moves when reaching rank 8' do
        pawn = place(described_class.new(:white, [6, 4]))
        promo_moves = pawn.moves(board).select { |m| m.type == :promotion }
        expect(promo_moves.size).to eq 4
        expect(promo_moves.map(&:promotion_piece)).to match_array(%i[queen rook bishop knight])
      end

      it 'does not generate a normal forward move when promoting' do
        pawn = place(described_class.new(:white, [6, 4]))
        normal_forward = pawn.moves(board).select { |m| m.to == [7, 4] && m.type == :normal }
        expect(normal_forward).to be_empty
      end

      it 'generates 4 promotion capture moves when capturing on the back rank' do
        pawn = place(described_class.new(:white, [6, 4]))
        place(Chess::Pieces::Rook.new(:black, [7, 5]))
        capture_promos = pawn.moves(board).select { |m| m.to == [7, 5] && m.type == :promotion }
        expect(capture_promos.size).to eq 4
      end
    end
  end

  # ══ BLACK PAWN ═════════════════════════════════════════════════════════════
  describe 'black pawn' do
    it 'moves one square forward (toward rank 0)' do
      pawn = place(described_class.new(:black, [4, 4]))
      expect(destinations(pawn)).to include([3, 4])
    end

    it 'moves two squares from starting rank (rank 6)' do
      pawn = place(described_class.new(:black, [6, 4]))
      expect(destinations(pawn)).to include([4, 4])
    end

    it 'cannot move in the white direction' do
      pawn = place(described_class.new(:black, [4, 4]))
      expect(destinations(pawn)).not_to include([5, 4])
    end

    it 'captures diagonally toward rank 0' do
      pawn = place(described_class.new(:black, [4, 4]))
      place(Chess::Pieces::Rook.new(:white, [3, 5]))
      expect(destinations(pawn)).to include([3, 5])
    end

    it 'generates 4 promotion moves when reaching rank 1' do
      pawn = place(described_class.new(:black, [1, 4]))
      promo_moves = pawn.moves(board).select { |m| m.type == :promotion }
      expect(promo_moves.size).to eq 4
      expect(promo_moves.map(&:to).uniq).to eq [[0, 4]]
    end

    it 'can capture en passant' do
      pawn = place(described_class.new(:black, [3, 4]))
      board.en_passant_target = [2, 5]
      ep = pawn.moves(board).find { |m| m.type == :en_passant }
      expect(ep).not_to be_nil
      expect(ep.to).to eq [2, 5]
    end
  end

  describe '#symbol' do
    it 'returns ♙ for white' do
      expect(described_class.new(:white, [1, 0]).symbol).to eq '♙'
    end

    it 'returns ♟ for black' do
      expect(described_class.new(:black, [6, 0]).symbol).to eq '♟'
    end
  end
end
