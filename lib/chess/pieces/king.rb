module Chess
  module Pieces
    class King < Piece
      DIRECTIONS = [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]].freeze

      def symbol = color == :white ? '♔' : '♚'

      def moves(board)
        step_moves(board, DIRECTIONS) + castling_moves(board)
      end

      private

      def castling_moves(board)
        return [] if moved?

        rank   = position[0]
        result = []

        ks_rook = board.piece_at([rank, 7])
        if rook_eligible?(ks_rook) &&
           board.empty?([rank, 5]) && board.empty?([rank, 6])
          result << Move.new(from: position, to: [rank, 6], type: :castle_kingside)
        end

        qs_rook = board.piece_at([rank, 0])
        if rook_eligible?(qs_rook) &&
           board.empty?([rank, 1]) && board.empty?([rank, 2]) && board.empty?([rank, 3])
          result << Move.new(from: position, to: [rank, 2], type: :castle_queenside)
        end

        result
      end

      def rook_eligible?(piece)
        piece&.type == :rook && piece.color == color && !piece.moved?
      end
    end
  end
end
