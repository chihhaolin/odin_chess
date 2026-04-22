require 'spec_helper'
require 'chess/cli/input_parser'

RSpec.describe Chess::CLI::InputParser do
  subject(:parser) { described_class.new }

  describe '#parse' do
    context 'commands' do
      it 'returns { type: :save } for "save"' do
        expect(parser.parse('save')).to eq({ type: :save })
      end

      it 'returns { type: :resign } for "resign"' do
        expect(parser.parse('resign')).to eq({ type: :resign })
      end

      it 'returns { type: :quit } for "quit"' do
        expect(parser.parse('quit')).to eq({ type: :quit })
      end

      it 'returns { type: :quit } for "exit"' do
        expect(parser.parse('exit')).to eq({ type: :quit })
      end

      it 'is case-insensitive for commands' do
        expect(parser.parse('SAVE')).to  eq({ type: :save })
        expect(parser.parse('Quit')).to  eq({ type: :quit })
      end

      it 'handles leading/trailing whitespace' do
        expect(parser.parse('  save  ')).to eq({ type: :save })
      end
    end

    context 'move parsing — spaced format' do
      it 'parses "e2 e4" to the correct positions' do
        result = parser.parse('e2 e4')
        expect(result[:type]).to eq(:move)
        expect(result[:from]).to eq([1, 4])
        expect(result[:to]).to   eq([3, 4])
      end

      it 'parses "a1 h8" (corner to corner)' do
        result = parser.parse('a1 h8')
        expect(result[:from]).to eq([0, 0])
        expect(result[:to]).to   eq([7, 7])
      end

      it 'parses "h8 a1"' do
        result = parser.parse('h8 a1')
        expect(result[:from]).to eq([7, 7])
        expect(result[:to]).to   eq([0, 0])
      end

      it 'sets promotion_piece to nil when no suffix given' do
        result = parser.parse('e2 e4')
        expect(result[:promotion_piece]).to be_nil
      end
    end

    context 'move parsing — compact format' do
      it 'parses "e2e4" to the correct positions' do
        result = parser.parse('e2e4')
        expect(result[:type]).to eq(:move)
        expect(result[:from]).to eq([1, 4])
        expect(result[:to]).to   eq([3, 4])
      end
    end

    context 'promotion moves' do
      it 'parses "e7 e8q" with promotion_piece :queen' do
        result = parser.parse('e7 e8q')
        expect(result[:type]).to            eq(:move)
        expect(result[:from]).to            eq([6, 4])
        expect(result[:to]).to              eq([7, 4])
        expect(result[:promotion_piece]).to eq(:queen)
      end

      it 'parses "e7 e8r" with promotion_piece :rook' do
        expect(parser.parse('e7 e8r')[:promotion_piece]).to eq(:rook)
      end

      it 'parses "e7 e8b" with promotion_piece :bishop' do
        expect(parser.parse('e7 e8b')[:promotion_piece]).to eq(:bishop)
      end

      it 'parses "e7 e8n" with promotion_piece :knight' do
        expect(parser.parse('e7 e8n')[:promotion_piece]).to eq(:knight)
      end

      it 'parses compact "e7e8q" with promotion_piece :queen' do
        result = parser.parse('e7e8q')
        expect(result[:type]).to            eq(:move)
        expect(result[:promotion_piece]).to eq(:queen)
      end

      it 'returns error for unknown promotion suffix' do
        result = parser.parse('e7 e8x')
        expect(result[:type]).to    eq(:error)
        expect(result[:message]).to include('x')
      end
    end

    context 'invalid input' do
      it 'returns { type: :error } for garbage input' do
        result = parser.parse('blah')
        expect(result[:type]).to eq(:error)
        expect(result[:message]).to be_a(String)
      end

      it 'returns { type: :error } for out-of-bounds square "z9 e4"' do
        result = parser.parse('z9 e4')
        expect(result[:type]).to eq(:error)
      end

      it 'returns { type: :error } for single square "e4"' do
        result = parser.parse('e4')
        expect(result[:type]).to eq(:error)
      end

      it 'returns { type: :error } for empty string' do
        result = parser.parse('')
        expect(result[:type]).to eq(:error)
      end
    end
  end
end
