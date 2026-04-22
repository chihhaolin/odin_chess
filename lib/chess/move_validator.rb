module Chess
  class MoveValidator
    def legal_moves(color, board)
      board.pieces(color).flat_map do |piece|
        piece.moves(board).select do |move|
          safe_after_move?(color, board, move) && !castling_blocked?(color, board, move)
        end
      end
    end

    def in_check?(color, board)
      king_pos = board.king_position(color)
      return false unless king_pos

      opponent = color == :white ? :black : :white
      board.pieces(opponent).any? do |piece|
        piece.moves(board).any? { |m| m.to == king_pos }
      end
    end

    def checkmate?(color, board)
      in_check?(color, board) && legal_moves(color, board).empty?
    end

    def stalemate?(color, board)
      !in_check?(color, board) && legal_moves(color, board).empty?
    end

    def apply_move!(board, move)
      case move.type
      when :castle_kingside, :castle_queenside
        apply_castling!(board, move)
      when :en_passant
        apply_en_passant!(board, move)
      else
        apply_normal!(board, move)
      end

      update_en_passant!(board, move)
    end

    private

    def safe_after_move?(color, board, move)
      cloned = board.deep_clone
      apply_move!(cloned, move)
      !in_check?(color, cloned)
    end

    def castling_blocked?(color, board, move)
      return false unless move.type == :castle_kingside || move.type == :castle_queenside

      return true if in_check?(color, board)

      rank       = move.from[0]
      pass_file  = move.type == :castle_kingside ? 5 : 3

      # Simulate king on the passing square and check if attacked
      cloned      = board.deep_clone
      king        = cloned.piece_at(move.from)
      cloned.grid[rank][4]         = nil
      cloned.grid[rank][pass_file] = king
      king.position                = [rank, pass_file]

      in_check?(color, cloned)
    end

    def apply_normal!(board, move)
      board.move_piece(move.from, move.to)

      if move.type == :promotion
        piece_class = PROMOTION_MAP[move.promotion_piece || :queen]
        color       = board.piece_at(move.to).color
        board.place(piece_class.new(color, move.to), move.to)
      end
    end

    def apply_castling!(board, move)
      rank = move.from[0]
      if move.type == :castle_kingside
        board.move_piece(move.from, [rank, 6])
        board.move_piece([rank, 7], [rank, 5])
      else
        board.move_piece(move.from, [rank, 2])
        board.move_piece([rank, 0], [rank, 3])
      end
    end

    def apply_en_passant!(board, move)
      board.move_piece(move.from, move.to)
      board.remove([move.from[0], move.to[1]])
    end

    def update_en_passant!(board, move)
      piece = board.piece_at(move.to)
      if piece.is_a?(Pieces::Pawn) && (move.to[0] - move.from[0]).abs == 2
        board.en_passant_target = [(move.from[0] + move.to[0]) / 2, move.from[1]]
      else
        board.en_passant_target = nil
      end
    end

    PROMOTION_MAP = {
      queen:  Pieces::Queen,
      rook:   Pieces::Rook,
      bishop: Pieces::Bishop,
      knight: Pieces::Knight
    }.freeze
  end
end
