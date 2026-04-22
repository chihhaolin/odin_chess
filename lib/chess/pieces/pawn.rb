module Chess
  module Pieces
    class Pawn < Piece
      PROMOTION_PIECES = %i[queen rook bishop knight].freeze

      def symbol = color == :white ? '♙' : '♟'

      def moves(board)
        forward_moves(board) + capture_moves(board) + en_passant_moves(board)
      end

      private

      def forward_dir  = color == :white ? 1 : -1
      def start_rank   = color == :white ? 1 : 6
      def promo_rank   = color == :white ? 7 : 0

      def forward_moves(board)
        result   = []
        rank, file = position
        one_step = rank + forward_dir

        return result unless (0..7).cover?(one_step) && board.empty?([one_step, file])

        if one_step == promo_rank
          PROMOTION_PIECES.each do |pp|
            result << Move.new(from: position, to: [one_step, file], type: :promotion, promotion_piece: pp)
          end
        else
          result << Move.new(from: position, to: [one_step, file])
        end

        # Two-square initial push
        two_step = rank + 2 * forward_dir
        if rank == start_rank && board.empty?([two_step, file])
          result << Move.new(from: position, to: [two_step, file])
        end

        result
      end

      def capture_moves(board)
        result     = []
        rank, file = position
        target_rank = rank + forward_dir

        return result unless (0..7).cover?(target_rank)

        [-1, 1].each do |df|
          target_file = file + df
          next unless (0..7).cover?(target_file)

          target = board.piece_at([target_rank, target_file])
          next unless target && target.color == opponent_color

          if target_rank == promo_rank
            PROMOTION_PIECES.each do |pp|
              result << Move.new(from: position, to: [target_rank, target_file],
                                 type: :promotion, promotion_piece: pp)
            end
          else
            result << Move.new(from: position, to: [target_rank, target_file])
          end
        end

        result
      end

      def en_passant_moves(board)
        ep = board.en_passant_target
        return [] unless ep

        rank, file = position
        target_rank = rank + forward_dir

        if ep[0] == target_rank && (ep[1] - file).abs == 1
          [Move.new(from: position, to: ep, type: :en_passant)]
        else
          []
        end
      end
    end
  end
end
