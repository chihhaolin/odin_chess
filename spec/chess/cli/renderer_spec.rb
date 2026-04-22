require 'spec_helper'
require 'chess/cli/renderer'

RSpec.describe Chess::CLI::Renderer do
  subject(:renderer) { described_class.new }

  let(:board) { Chess::Board.new }

  describe '#render' do
    context 'output structure' do
      it 'includes file labels a through h on top and bottom rows' do
        output = renderer.render(board)
        lines  = output.split("\n")
        expect(lines.first).to include('a')
        expect(lines.first).to include('h')
        expect(lines.last).to  include('a')
        expect(lines.last).to  include('h')
      end

      it 'includes rank labels 1 through 8' do
        output = renderer.render(board)
        (1..8).each { |r| expect(output).to include(r.to_s) }
      end

      it 'produces exactly 10 lines (header + 8 ranks + footer)' do
        output = renderer.render(board)
        expect(output.split("\n").length).to eq(10)
      end
    end

    context 'piece rendering' do
      before { board.setup_initial_position }

      it 'renders white king symbol ♔' do
        expect(renderer.render(board)).to include('♔')
      end

      it 'renders black king symbol ♚' do
        expect(renderer.render(board)).to include('♚')
      end

      it 'renders white pawns ♙' do
        expect(renderer.render(board)).to include('♙')
      end

      it 'renders black pawns ♟' do
        expect(renderer.render(board)).to include('♟')
      end
    end

    context 'last_move highlight' do
      it 'does not crash when last_move is nil' do
        expect { renderer.render(board, last_move: nil) }.not_to raise_error
      end

      it 'applies highlight ANSI code when last_move is given' do
        move = Chess::Move.new(from: [1, 4], to: [3, 4])
        output = renderer.render(board, last_move: move)
        expect(output).to include(described_class::HIGHLIGHT_BG)
      end

      it 'does not apply highlight when no last_move' do
        output = renderer.render(board)
        expect(output).not_to include(described_class::HIGHLIGHT_BG)
      end
    end

    context 'check highlight' do
      before { board.setup_initial_position }

      it 'applies check ANSI code on king square when in_check_color given' do
        output = renderer.render(board, in_check_color: :white)
        expect(output).to include(described_class::CHECK_BG)
      end

      it 'does not apply check highlight when in_check_color is nil' do
        output = renderer.render(board, in_check_color: nil)
        expect(output).not_to include(described_class::CHECK_BG)
      end
    end

    context 'ANSI reset codes' do
      it 'contains reset codes to avoid colour bleed' do
        output = renderer.render(board)
        expect(output).to include(described_class::RESET)
      end
    end

    context 'empty board' do
      it 'renders without crashing and contains no piece symbols' do
        output = renderer.render(board)
        %w[♔ ♕ ♖ ♗ ♘ ♙ ♚ ♛ ♜ ♝ ♞ ♟].each do |sym|
          expect(output).not_to include(sym)
        end
      end
    end
  end
end
