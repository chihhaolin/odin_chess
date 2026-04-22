require 'sinatra/base'
require 'json'
require 'fileutils'
require_relative '../lib/chess'
require_relative 'game_store'

module Chess
  class API < Sinatra::Base
    SAVES_DIR = File.expand_path('../../saves', __dir__)

    configure do
      set :store,         GameStore.new
      set :saves_dir,     SAVES_DIR
      set :public_folder, File.expand_path('../frontend', __dir__)
      enable :static
    end

    before do
      content_type :json
      response.headers['Access-Control-Allow-Origin']  = '*'
      response.headers['Access-Control-Allow-Methods'] = 'GET, POST, DELETE, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    end

    options '/*' do
      200
    end

    get '/' do
      content_type :html
      send_file File.join(settings.public_folder, 'index.html')
    end

    # ------------------------------------------------------------------ #
    # Games                                                               #
    # ------------------------------------------------------------------ #

    post '/games' do
      game_id = settings.store.create
      game    = settings.store.get(game_id)
      status 201
      { game_id: game_id, state: build_state(game) }.to_json
    end

    # Must be defined before /games/:id to avoid shadowing
    get '/games/saved' do
      files = list_save_files
      { saves: files.map { |f| File.basename(f) } }.to_json
    end

    get '/games/:id' do
      game = find_game(params[:id])
      { state: build_state(game) }.to_json
    end

    post '/games/:id/moves' do
      game = find_game(params[:id])
      data = parse_body

      halt 400, { error: 'Missing from/to' }.to_json unless data['from'] && data['to']

      from_sq = data['from'].to_s.downcase
      to_sq   = data['to'].to_s.downcase

      unless from_sq =~ /\A[a-h][1-8]\z/ && to_sq =~ /\A[a-h][1-8]\z/
        halt 400, { error: "Invalid square (expected a1–h8)" }.to_json
      end

      from  = square_to_pos(from_sq)
      to    = square_to_pos(to_sq)
      promo = data['promotion']&.to_sym

      candidates = game.legal_moves.select do |m|
        m.from == from && m.to == to &&
          (promo.nil? || m.promotion_piece == promo)
      end

      if candidates.empty?
        halt 422, { error: 'Illegal move', state: build_state(game) }.to_json
      end

      if candidates.any? { |m| m.type == :promotion } && promo.nil?
        halt 422, { error: 'Promotion piece required: queen, rook, bishop, or knight',
                    state: build_state(game) }.to_json
      end

      result = game.make_move(candidates.first)
      if result[:success]
        { status: result[:status], state: build_state(game), message: result[:message] }.to_json
      else
        halt 422, { error: result[:message], state: build_state(game) }.to_json
      end
    end

    post '/games/:id/save' do
      game = find_game(params[:id])
      FileUtils.mkdir_p(settings.saves_dir)
      filename = "save_#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{params[:id][0..7]}.yml"
      path     = File.join(settings.saves_dir, filename)
      Serializer.save(game, path)
      { saved: filename }.to_json
    end

    # Must be defined before /games/:id to avoid shadowing
    post '/games/load/:save_name' do
      path = File.join(settings.saves_dir, params[:save_name])
      halt 404, { error: 'Save not found' }.to_json unless File.exist?(path)

      begin
        game    = Serializer.load(path)
        game_id = settings.store.load(game)
        status 201
        { game_id: game_id, state: build_state(game) }.to_json
      rescue StandardError => e
        halt 422, { error: e.message }.to_json
      end
    end

    # Must be defined before DELETE /games/:id
    delete '/games/saved/:save_name' do
      path = File.join(settings.saves_dir, params[:save_name])
      halt 404, { error: 'Save not found' }.to_json unless File.exist?(path)
      File.delete(path)
      { deleted: params[:save_name] }.to_json
    end

    delete '/games/:id' do
      game = find_game(params[:id])
      winner = game.current_turn == :white ? 'Black' : 'White'
      message = "#{game.current_turn.to_s.capitalize} resigns. #{winner} wins!"
      settings.store.delete(params[:id])
      { message: message }.to_json
    end

    # ------------------------------------------------------------------ #
    # Helpers                                                             #
    # ------------------------------------------------------------------ #
    private

    def find_game(id)
      game = settings.store.get(id)
      halt 404, { error: 'Game not found' }.to_json unless game
      game
    end

    def parse_body
      request.body.rewind
      raw = request.body.read
      return {} if raw.empty?
      JSON.parse(raw)
    rescue JSON::ParserError
      halt 400, { error: 'Invalid JSON body' }.to_json
    end

    def build_state(game)
      last = game.move_history.last
      {
        board:       game.current_state[:board],
        turn:        game.current_turn,
        status:      game.status,
        legal_moves: build_legal_moves(game),
        last_move:   last ? { from: pos_to_square(last.from), to: pos_to_square(last.to) } : nil,
        message:     game_message(game)
      }
    end

    def build_legal_moves(game)
      game.legal_moves.each_with_object({}) do |move, h|
        sq = pos_to_square(move.from)
        h[sq] ||= []
        h[sq] << pos_to_square(move.to)
        h[sq].uniq!
      end
    end

    def game_message(game)
      case game.status
      when :checkmate
        winner = game.current_turn == :white ? 'Black' : 'White'
        "Checkmate! #{winner} wins."
      when :stalemate then "Stalemate! It's a draw."
      when :check     then "#{game.current_turn.to_s.capitalize} is in check!"
      else                 "#{game.current_turn.to_s.capitalize}'s turn."
      end
    end

    def square_to_pos(sq)
      [sq[1].to_i - 1, sq[0].ord - 'a'.ord]
    end

    def pos_to_square(pos)
      "#{('a'.ord + pos[1]).chr}#{pos[0] + 1}"
    end

    def list_save_files
      return [] unless Dir.exist?(settings.saves_dir)
      Dir.glob(File.join(settings.saves_dir, '*.yml')).sort
    end
  end
end
