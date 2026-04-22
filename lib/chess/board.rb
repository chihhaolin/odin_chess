module Chess
  class Board
    attr_accessor :en_passant_target, :grid

    def initialize
      @grid              = Array.new(8) { Array.new(8, nil) }
      @en_passant_target = nil
    end

    def piece_at(pos)
      @grid[pos[0]][pos[1]]
    end

    def place(piece, pos)
      @grid[pos[0]][pos[1]] = piece
      piece.position = pos.dup if piece
    end

    def remove(pos)
      piece = piece_at(pos)
      @grid[pos[0]][pos[1]] = nil
      piece
    end

    def move_piece(from, to)
      piece = piece_at(from)
      @grid[from[0]][from[1]] = nil
      @grid[to[0]][to[1]]     = piece
      piece.position = to.dup if piece
      piece.moved    = true   if piece
      piece
    end

    def empty?(pos)
      piece_at(pos).nil?
    end

    def pieces(color = nil)
      all = @grid.flatten.compact
      color ? all.select { |p| p.color == color } : all
    end

    def king_position(color)
      pieces(color).find { |p| p.is_a?(Pieces::King) }&.position
    end

    def deep_clone
      cloned                    = Board.new
      cloned.en_passant_target  = @en_passant_target&.dup
      @grid.each_with_index do |row, rank|
        row.each_with_index do |piece, file|
          next unless piece
          new_piece          = piece.dup
          new_piece.position = [rank, file]
          cloned.grid[rank][file] = new_piece
        end
      end
      cloned
    end

    def setup_initial_position
      place_back_rank(:white, 0)
      place_pawns(:white, 1)
      place_back_rank(:black, 7)
      place_pawns(:black, 6)
    end

    private

    def place_back_rank(color, rank)
      [Pieces::Rook, Pieces::Knight, Pieces::Bishop, Pieces::Queen,
       Pieces::King, Pieces::Bishop, Pieces::Knight, Pieces::Rook].each_with_index do |klass, file|
        piece = klass.new(color, [rank, file])
        place(piece, [rank, file])
      end
    end

    def place_pawns(color, rank)
      8.times { |file| place(Pieces::Pawn.new(color, [rank, file]), [rank, file]) }
    end
  end
end
