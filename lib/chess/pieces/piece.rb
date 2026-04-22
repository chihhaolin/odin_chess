module Chess
  module Pieces
    class Piece
      attr_reader :color
      attr_accessor :position, :moved

      def initialize(color, position)
        @color    = color
        @position = position.dup
        @moved    = false
      end

      def moves(_board)
        raise NotImplementedError, "#{self.class} must implement #moves"
      end

      def opponent_color
        color == :white ? :black : :white
      end

      def moved? = @moved

      def symbol
        raise NotImplementedError
      end

      def type
        self.class.name.split('::').last.downcase.to_sym
      end

      def dup
        copy = super
        copy.position = @position.dup
        copy
      end

      protected

      def in_bounds?(rank, file)
        rank.between?(0, 7) && file.between?(0, 7)
      end

      def slide_moves(board, directions)
        result = []
        rank, file = position
        directions.each do |dr, df|
          r, f = rank + dr, file + df
          while in_bounds?(r, f)
            target = board.piece_at([r, f])
            if target.nil?
              result << Move.new(from: position, to: [r, f])
            elsif target.color == opponent_color
              result << Move.new(from: position, to: [r, f])
              break
            else
              break
            end
            r += dr
            f += df
          end
        end
        result
      end

      def step_moves(board, directions)
        result = []
        rank, file = position
        directions.each do |dr, df|
          r, f = rank + dr, file + df
          next unless in_bounds?(r, f)
          target = board.piece_at([r, f])
          result << Move.new(from: position, to: [r, f]) if target.nil? || target.color == opponent_color
        end
        result
      end
    end
  end
end
