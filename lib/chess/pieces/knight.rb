module Chess
  module Pieces
    class Knight < Piece
      DELTAS = [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]].freeze

      def symbol = color == :white ? '♘' : '♞'

      def moves(board)
        step_moves(board, DELTAS)
      end
    end
  end
end
