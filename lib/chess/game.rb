module Chess
  class Game
    attr_reader :board, :current_turn, :status, :move_history

    def initialize
      @board        = Board.new
      @board.setup_initial_position
      @current_turn = :white
      @status       = :playing
      @move_history = []
      @validator    = MoveValidator.new
    end

    def make_move(move)
      unless legal_move?(move)
        return { success: false, status: :illegal, message: "Illegal move: #{move}" }
      end

      @validator.apply_move!(@board, move)
      @move_history << move
      switch_turn
      update_status

      { success: true, status: @status, message: status_message }
    end

    def legal_moves(color = @current_turn)
      @validator.legal_moves(color, @board)
    end

    def in_check?(color = @current_turn)
      @validator.in_check?(color, @board)
    end

    def over?
      %i[checkmate stalemate].include?(@status)
    end

    def current_state
      {
        board:              board_to_h,
        turn:               @current_turn,
        status:             @status,
        en_passant_target:  @board.en_passant_target
      }
    end

    private

    def legal_move?(move)
      legal_moves.any? { |m| m == move }
    end

    def switch_turn
      @current_turn = @current_turn == :white ? :black : :white
    end

    def update_status
      if @validator.checkmate?(@current_turn, @board)
        @status = :checkmate
      elsif @validator.stalemate?(@current_turn, @board)
        @status = :stalemate
      elsif @validator.in_check?(@current_turn, @board)
        @status = :check
      else
        @status = :playing
      end
    end

    def status_message
      case @status
      when :checkmate
        winner = @current_turn == :white ? 'Black' : 'White'
        "Checkmate! #{winner} wins."
      when :stalemate
        "Stalemate! It's a draw."
      when :check
        "#{@current_turn.to_s.capitalize} is in check!"
      else
        "#{@current_turn.to_s.capitalize}'s turn."
      end
    end

    def board_to_h
      {}.tap do |h|
        @board.grid.each_with_index do |row, rank|
          row.each_with_index do |piece, file|
            key = "#{('a'.ord + file).chr}#{rank + 1}"
            h[key] = piece ? { type: piece.type, color: piece.color } : nil
          end
        end
      end
    end
  end
end
