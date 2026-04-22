require 'fileutils'

module Chess
  module CLI
    class Runner
      SAVES_DIR = File.expand_path('../../../../saves', __dir__)

      def initialize(input: $stdin, output: $stdout)
        @input    = input
        @output   = output
        @renderer = Renderer.new
        @parser   = InputParser.new
      end

      def start
        @output.puts "╔══════════════════════╗"
        @output.puts "║       CHESS          ║"
        @output.puts "╚══════════════════════╝"
        @output.puts "Commands: <from> <to>  |  save  |  resign  |  quit"
        @output.puts ""

        @game = ask_new_or_load
        run_game_loop
      end

      private

      def run_game_loop
        until @game.over?
          print_board
          print_turn_info
          handle_input
        end
        print_board
        print_game_over
      end

      def print_board
        last_move = @game.move_history.last
        check_col  = @game.in_check? ? @game.current_turn : nil
        @output.puts @renderer.render(@game.board, last_move: last_move, in_check_color: check_col)
        @output.puts ""
      end

      def print_turn_info
        status = @game.status
        turn   = @game.current_turn.to_s.capitalize
        if status == :check
          @output.puts "#{turn}'s turn  ⚠  CHECK!"
        else
          @output.puts "#{turn}'s turn"
        end
      end

      def print_game_over
        case @game.status
        when :checkmate
          winner = @game.current_turn == :white ? 'Black' : 'White'
          @output.puts "Checkmate! #{winner} wins."
        when :stalemate
          @output.puts "Stalemate — it's a draw."
        end
      end

      def handle_input
        @output.print "> "
        raw   = @input.gets
        input = raw ? raw.chomp : 'quit'
        result = @parser.parse(input)
        case result[:type]
        when :save   then do_save
        when :resign then do_resign
        when :quit   then do_quit
        when :move   then do_move(result)
        when :error  then @output.puts result[:message]
        end
      end

      def do_move(parsed)
        from = parsed[:from]
        to   = parsed[:to]

        candidates = @game.legal_moves.select { |m| m.from == from && m.to == to }

        if candidates.empty?
          @output.puts "Illegal move: #{pos_to_square(from)} → #{pos_to_square(to)}"
          return
        end

        if candidates.any? { |m| m.type == :promotion }
          promo = parsed[:promotion_piece] || ask_promotion_piece
          move  = candidates.find { |m| m.promotion_piece == promo }
          unless move
            @output.puts "Invalid promotion piece. Choose q, r, b, or n."
            return
          end
        else
          move = candidates.first
        end

        @game.make_move(move)
      end

      def do_save
        FileUtils.mkdir_p(SAVES_DIR)
        filename = "save_#{Time.now.strftime('%Y%m%d_%H%M%S')}.yml"
        path     = File.join(SAVES_DIR, filename)
        Serializer.save(@game, path)
        @output.puts "Saved → #{path}"
      end

      def do_resign
        winner = @game.current_turn == :white ? 'Black' : 'White'
        @output.puts "#{@game.current_turn.to_s.capitalize} resigns. #{winner} wins!"
        exit(0)
      end

      def do_quit
        @output.puts "Goodbye!"
        exit(0)
      end

      def ask_new_or_load
        saves = list_saves
        if saves.empty?
          return Game.new
        end

        @output.puts "Saved games:"
        saves.each_with_index { |s, i| @output.puts "  #{i + 1}. #{File.basename(s)}" }
        @output.puts "  n. New game"
        @output.print "Choice [n]: "
        choice = @input.gets&.chomp&.strip&.downcase || 'n'

        if choice == 'n' || choice.empty?
          Game.new
        else
          idx = choice.to_i - 1
          if idx.between?(0, saves.length - 1)
            load_save(saves[idx])
          else
            @output.puts "Invalid choice, starting new game."
            Game.new
          end
        end
      end

      def load_save(path)
        Serializer.load(path)
      rescue StandardError => e
        @output.puts "Error loading save: #{e.message}. Starting new game."
        Game.new
      end

      def ask_promotion_piece
        @output.puts "Promote pawn to: (q)ueen  (r)ook  (b)ishop  (n)knight"
        @output.print "> "
        input = @input.gets&.chomp&.strip&.downcase || 'q'
        { 'q' => :queen, 'r' => :rook, 'b' => :bishop, 'n' => :knight }[input] || :queen
      end

      def list_saves
        return [] unless Dir.exist?(SAVES_DIR)
        Dir.glob(File.join(SAVES_DIR, '*.yml')).sort
      end

      def pos_to_square(pos)
        "#{('a'.ord + pos[1]).chr}#{pos[0] + 1}"
      end
    end
  end
end
