require 'spec_helper'
require 'rack/test'
require 'json'
require 'tmpdir'
require 'app/api'

# Integration tests: exercises the full HTTP stack from Rack through
# API routing, GameStore, Chess engine, and Serializer — no mocking.
RSpec.describe 'Phase 3 API integration' do
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

  def api_move(game_id, from, to, opts = {})
    body = { from: from, to: to }.merge(opts)
    post "/games/#{game_id}/moves", body.to_json, 'CONTENT_TYPE' => 'application/json'
    json_body
  end

  # ------------------------------------------------------------------ #
  # Scholar's Mate (4-move checkmate) via HTTP                          #
  # ------------------------------------------------------------------ #
  describe "Scholar's Mate via HTTP" do
    it 'ends in checkmate after the full 7-move sequence' do
      post '/games'
      id = json_body['game_id']

      api_move(id, 'e2', 'e4')
      api_move(id, 'e7', 'e5')
      api_move(id, 'd1', 'h5')
      api_move(id, 'b8', 'c6')
      api_move(id, 'f1', 'c4')
      api_move(id, 'a7', 'a6')
      result = api_move(id, 'h5', 'f7')

      expect(result['state']['status']).to eq('checkmate')
      expect(result['status']).to eq('checkmate')
    end
  end

  # ------------------------------------------------------------------ #
  # Save and load round-trip                                            #
  # ------------------------------------------------------------------ #
  describe 'save → load round-trip' do
    it 'preserves board position and turn across save/load' do
      post '/games'
      id = json_body['game_id']

      api_move(id, 'e2', 'e4')
      api_move(id, 'e7', 'e5')

      post "/games/#{id}/save"
      save_name = json_body['saved']

      post "/games/load/#{save_name}"
      loaded = json_body
      state  = loaded['state']

      expect(state['turn']).to eq('white')
      expect(state['board']['e4']).to eq({ 'type' => 'pawn', 'color' => 'white' })
      expect(state['board']['e5']).to eq({ 'type' => 'pawn', 'color' => 'black' })
      expect(state['board']['e2']).to be_nil
      expect(state['board']['e7']).to be_nil
    end
  end

  # ------------------------------------------------------------------ #
  # Resign via DELETE                                                   #
  # ------------------------------------------------------------------ #
  describe 'resign via DELETE /games/:id' do
    it 'reports the correct winner and removes the game' do
      post '/games'
      id = json_body['game_id']

      delete "/games/#{id}"
      expect(last_response.status).to eq(200)
      expect(json_body['message']).to include('White resigns')
      expect(json_body['message']).to include('Black wins')

      get "/games/#{id}"
      expect(last_response.status).to eq(404)
    end
  end
end
