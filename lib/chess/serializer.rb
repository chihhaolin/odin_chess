require 'yaml'

module Chess
  class Serializer
    def self.save(game, path)
      File.write(path, YAML.dump(game_to_h(game)))
    end

    def self.load(path)
      data = YAML.safe_load(File.read(path), permitted_classes: [Symbol])
      h_to_game(data)
    end

    private

    def self.game_to_h(game)
      {
        'current_turn' => game.current_turn.to_s,
        'board'        => board_to_h(game.board),
        'move_history' => game.move_history.map { |m| move_to_h(m) }
      }
    end

    def self.board_to_h(board)
      {
        'en_passant_target' => board.en_passant_target,
        'pieces'            => board.pieces.map { |p| piece_to_h(p) }
      }
    end

    def self.piece_to_h(piece)
      {
        'type'     => piece.type.to_s,
        'color'    => piece.color.to_s,
        'position' => piece.position,
        'moved'    => piece.moved?
      }
    end

    def self.move_to_h(move)
      {
        'from'            => move.from,
        'to'              => move.to,
        'type'            => move.type.to_s,
        'promotion_piece' => move.promotion_piece&.to_s
      }
    end

    def self.h_to_game(data)
      board = Board.new
      data['board']['pieces'].each do |pd|
        piece          = build_piece(pd['type'].to_sym, pd['color'].to_sym, pd['position'])
        piece.moved    = pd['moved']
        board.place(piece, pd['position'])
      end
      board.en_passant_target = data['board']['en_passant_target']

      game = Game.allocate
      game.instance_variable_set(:@board,        board)
      game.instance_variable_set(:@current_turn, data['current_turn'].to_sym)
      game.instance_variable_set(:@move_history, data['move_history'].map { |md| h_to_move(md) })
      game.instance_variable_set(:@status,       :playing)
      game.instance_variable_set(:@validator,    MoveValidator.new)
      game.send(:update_status)
      game
    end

    def self.h_to_move(data)
      Move.new(
        from:            data['from'],
        to:              data['to'],
        type:            data['type'].to_sym,
        promotion_piece: data['promotion_piece']&.to_sym
      )
    end

    def self.build_piece(type, color, position)
      klass = { king: Pieces::King, queen: Pieces::Queen, rook: Pieces::Rook,
                bishop: Pieces::Bishop, knight: Pieces::Knight, pawn: Pieces::Pawn }[type]
      klass.new(color, position)
    end
  end
end
