require 'spec_helper'
require 'rack/test'
require 'json'
require 'tmpdir'
require 'app/api'

RSpec.describe Chess::API do
  include Rack::Test::Methods

  def app = Chess::API

  let(:tmp_dir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmp_dir) }

  before do
    Chess::API.set :store,     Chess::GameStore.new
    Chess::API.set :saves_dir, tmp_dir
  end

  def json_body
    JSON.parse(last_response.body)
  end

  def create_game
    post '/games'
    json_body['game_id']
  end

  # ------------------------------------------------------------------ #
  # POST /games                                                         #
  # ------------------------------------------------------------------ #
  describe 'POST /games' do
    it 'returns 201' do
      post '/games'
      expect(last_response.status).to eq(201)
    end

    it 'response includes game_id' do
      post '/games'
      expect(json_body).to have_key('game_id')
    end

    it 'response state includes board, turn, status, legal_moves' do
      post '/games'
      state = json_body['state']
      expect(state.keys).to include('board', 'turn', 'status', 'legal_moves')
    end
  end

  # ------------------------------------------------------------------ #
  # GET /games/saved                                                    #
  # ------------------------------------------------------------------ #
  describe 'GET /games/saved' do
    it 'returns 200 with saves array' do
      get '/games/saved'
      expect(last_response.status).to eq(200)
      expect(json_body).to have_key('saves')
    end

    it 'lists yml files present in the saves directory' do
      FileUtils.touch(File.join(tmp_dir, 'game1.yml'))
      get '/games/saved'
      expect(json_body['saves']).to include('game1.yml')
    end
  end

  # ------------------------------------------------------------------ #
  # GET /games/:id                                                      #
  # ------------------------------------------------------------------ #
  describe 'GET /games/:id' do
    it 'returns 200 with state for a valid game' do
      id = create_game
      get "/games/#{id}"
      expect(last_response.status).to eq(200)
      expect(json_body).to have_key('state')
    end

    it 'returns 404 for an unknown game id' do
      get '/games/no-such-id'
      expect(last_response.status).to eq(404)
    end
  end

  # ------------------------------------------------------------------ #
  # POST /games/:id/moves                                               #
  # ------------------------------------------------------------------ #
  describe 'POST /games/:id/moves' do
    let(:game_id) { create_game }

    def move(from, to, opts = {})
      body = { from: from, to: to }.merge(opts)
      post "/games/#{game_id}/moves", body.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'valid move returns 200 with updated state' do
      move('e2', 'e4')
      expect(last_response.status).to eq(200)
      expect(json_body['state']['turn']).to eq('black')
    end

    it 'illegal move returns 422' do
      move('e2', 'e5')
      expect(last_response.status).to eq(422)
      expect(json_body).to have_key('error')
    end

    it 'missing from/to returns 400' do
      post "/games/#{game_id}/moves", '{}', 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
    end

    it 'invalid square format returns 400' do
      move('z9', 'a1')
      expect(last_response.status).to eq(400)
    end

    it 'returns 404 for unknown game' do
      post '/games/bad-id/moves', { from: 'e2', to: 'e4' }.to_json,
           'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(404)
    end

    context 'pawn promotion' do
      let(:promotion_game_id) do
        game = Chess::Game.allocate
        board = Chess::Board.new
        board.place(Chess::Pieces::King.new(:white, [0, 4]), [0, 4])
        board.place(Chess::Pieces::King.new(:black, [7, 0]), [7, 0])
        board.place(Chess::Pieces::Pawn.new(:white, [6, 4]), [6, 4])
        game.instance_variable_set(:@board,        board)
        game.instance_variable_set(:@current_turn, :white)
        game.instance_variable_set(:@move_history, [])
        game.instance_variable_set(:@status,       :playing)
        game.instance_variable_set(:@validator,    Chess::MoveValidator.new)
        game.send(:update_status)
        Chess::API.settings.store.load(game)
      end

      it 'promotion without piece returns 422 with helpful message' do
        post "/games/#{promotion_game_id}/moves",
             { from: 'e7', to: 'e8' }.to_json, 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq(422)
        expect(json_body['error']).to include('Promotion piece required')
      end

      it 'promotion with piece returns 200 and promoted queen in board' do
        post "/games/#{promotion_game_id}/moves",
             { from: 'e7', to: 'e8', promotion: 'queen' }.to_json,
             'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq(200)
        expect(json_body['state']['board']['e8']).to eq({ 'type' => 'queen', 'color' => 'white' })
      end
    end
  end

  # ------------------------------------------------------------------ #
  # POST /games/:id/save                                                #
  # ------------------------------------------------------------------ #
  describe 'POST /games/:id/save' do
    it 'creates a .yml file in saves_dir' do
      id = create_game
      post "/games/#{id}/save"
      expect(Dir.glob(File.join(tmp_dir, '*.yml'))).not_to be_empty
    end

    it 'response includes saved filename' do
      id = create_game
      post "/games/#{id}/save"
      expect(json_body).to have_key('saved')
      expect(json_body['saved']).to end_with('.yml')
    end
  end

  # ------------------------------------------------------------------ #
  # POST /games/load/:save_name                                         #
  # ------------------------------------------------------------------ #
  describe 'POST /games/load/:save_name' do
    let(:save_name) do
      game = Chess::Game.new
      name = 'test_save.yml'
      Chess::Serializer.save(game, File.join(tmp_dir, name))
      name
    end

    it 'returns 201 with game_id and state' do
      post "/games/load/#{save_name}"
      expect(last_response.status).to eq(201)
      expect(json_body.keys).to include('game_id', 'state')
    end

    it 'returns 404 for an unknown save name' do
      post '/games/load/no_such.yml'
      expect(last_response.status).to eq(404)
    end

    it 'restored state reflects the saved game' do
      game = Chess::Game.new
      # Make a move so position is non-initial
      legal = game.legal_moves.find { |m| m.from == [1, 4] && m.to == [3, 4] }
      game.make_move(legal)
      name = 'moved_save.yml'
      Chess::Serializer.save(game, File.join(tmp_dir, name))

      post "/games/load/#{name}"
      expect(json_body['state']['turn']).to eq('black')
      expect(json_body['state']['board']['e4']).to eq({ 'type' => 'pawn', 'color' => 'white' })
    end
  end

  # ------------------------------------------------------------------ #
  # DELETE /games/saved/:save_name                                      #
  # ------------------------------------------------------------------ #
  describe 'DELETE /games/saved/:save_name' do
    it 'deletes the file and returns 200' do
      name = 'to_delete.yml'
      FileUtils.touch(File.join(tmp_dir, name))
      delete "/games/saved/#{name}"
      expect(last_response.status).to eq(200)
      expect(File.exist?(File.join(tmp_dir, name))).to be false
    end

    it 'returns 404 for unknown save' do
      delete '/games/saved/nonexistent.yml'
      expect(last_response.status).to eq(404)
    end
  end

  # ------------------------------------------------------------------ #
  # DELETE /games/:id                                                   #
  # ------------------------------------------------------------------ #
  describe 'DELETE /games/:id' do
    it 'returns 200 with a resign message' do
      id = create_game
      delete "/games/#{id}"
      expect(last_response.status).to eq(200)
      expect(json_body['message']).to include('resigns')
    end

    it 'game is no longer accessible after deletion' do
      id = create_game
      delete "/games/#{id}"
      get "/games/#{id}"
      expect(last_response.status).to eq(404)
    end

    it 'returns 404 for unknown game' do
      delete '/games/bad-id'
      expect(last_response.status).to eq(404)
    end
  end
end
