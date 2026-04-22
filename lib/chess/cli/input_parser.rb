module Chess
  module CLI
    class InputParser
      PROMOTION_MAP = { 'q' => :queen, 'r' => :rook, 'b' => :bishop, 'n' => :knight }.freeze

      # Returns one of:
      #   { type: :move, from: [rank,file], to: [rank,file], promotion_piece: Symbol|nil }
      #   { type: :save }
      #   { type: :resign }
      #   { type: :quit }
      #   { type: :error, message: String }
      def parse(input)
        s = input.strip.downcase
        case s
        when 'save'         then { type: :save }
        when 'resign'       then { type: :resign }
        when 'quit', 'exit' then { type: :quit }
        else parse_move(s)
        end
      end

      private

      def parse_move(s)
        # "e2 e4", "e2e4", "e7 e8q", "e7e8q"
        from_sq, to_sq, promo_char = extract_parts(s)
        return { type: :error, message: "Invalid input '#{s}'. Use format: e2 e4 (or e7 e8q for promotion)." } unless from_sq

        promotion_piece = promo_char ? PROMOTION_MAP[promo_char] : nil
        if promo_char && !promotion_piece
          return { type: :error, message: "Unknown promotion piece '#{promo_char}'. Use q, r, b, or n." }
        end

        { type: :move, from: square_to_pos(from_sq), to: square_to_pos(to_sq), promotion_piece: promotion_piece }
      end

      def extract_parts(s)
        # spaced: "e2 e4" or "e7 e8q"
        if s =~ /\A([a-h][1-8])\s+([a-h][1-8])([qrbn])?\z/
          return [$1, $2, $3]
        end
        # compact: "e2e4" or "e7e8q"
        if s =~ /\A([a-h][1-8])([a-h][1-8])([qrbn])?\z/
          return [$1, $2, $3]
        end
        nil
      end

      def square_to_pos(sq)
        file = sq[0].ord - 'a'.ord
        rank = sq[1].to_i - 1
        [rank, file]
      end
    end
  end
end
