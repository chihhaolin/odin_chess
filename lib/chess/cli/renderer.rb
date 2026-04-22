module Chess
  module CLI
    class Renderer
      # ANSI 256-color backgrounds
      LIGHT_BG     = "\e[48;5;222m"   # warm beige — light square
      DARK_BG      = "\e[48;5;94m"    # brown      — dark square
      HIGHLIGHT_BG = "\e[48;5;226m"   # yellow     — last-move square
      CHECK_BG     = "\e[48;5;160m"   # red        — king in check
      WHITE_FG     = "\e[97m"
      BLACK_FG     = "\e[30m"
      RESET        = "\e[0m"

      # render(board, last_move: Move|nil, in_check_color: :white|:black|nil) → String
      def render(board, last_move: nil, in_check_color: nil)
        check_king_pos = in_check_color ? board.king_position(in_check_color) : nil
        last_squares   = last_move ? [last_move.from, last_move.to] : []

        lines = ["  a  b  c  d  e  f  g  h"]
        7.downto(0) do |rank|
          row = "#{rank + 1}"
          8.times do |file|
            pos   = [rank, file]
            piece = board.piece_at(pos)
            bg    = choose_bg(rank, file, pos, check_king_pos, last_squares)
            sym   = piece ? piece.symbol : ' '
            fg    = piece ? (piece.color == :white ? WHITE_FG : BLACK_FG) : ''
            row  += "#{bg}#{fg} #{sym} #{RESET}"
          end
          row += " #{rank + 1}"
          lines << row
        end
        lines << "  a  b  c  d  e  f  g  h"
        lines.join("\n")
      end

      private

      def choose_bg(rank, file, pos, check_king_pos, last_squares)
        return CHECK_BG     if pos == check_king_pos
        return HIGHLIGHT_BG if last_squares.include?(pos)
        (rank + file).even? ? DARK_BG : LIGHT_BG
      end
    end
  end
end
