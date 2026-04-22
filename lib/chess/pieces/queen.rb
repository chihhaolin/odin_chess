module Chess
  module Pieces
    class Queen < Piece
      DIRECTIONS = [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]].freeze

      def symbol = color == :white ? '♕' : '♛'

      def moves(board)
        slide_moves(board, DIRECTIONS)
      end
    end
  end
end
