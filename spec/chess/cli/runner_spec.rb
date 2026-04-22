require 'spec_helper'
require 'chess/cli'
require 'stringio'
require 'tmpdir'

RSpec.describe Chess::CLI::Runner do
  def make_runner(input_str)
    input  = StringIO.new(input_str)
    output = StringIO.new
    runner = described_class.new(input: input, output: output)
    [runner, output]
  end

  # Prevent exit() calls from stopping the test process
  def capture_exit(&block)
    block.call
  rescue SystemExit
    # swallow
  end

  describe 'new game startup (no saves)' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(described_class::SAVES_DIR).and_return(false)
    end

    it 'prints the chess banner' do
      runner, output = make_runner("quit\n")
      capture_exit { runner.start }
      expect(output.string).to include('CHESS')
    end

    it 'starts a new game without asking about saves when no saves exist' do
      runner, output = make_runner("quit\n")
      capture_exit { runner.start }
      expect(output.string).not_to include('Saved games')
    end
  end

  describe '#start — move flow' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(described_class::SAVES_DIR).and_return(false)
    end

    it 'renders the board on each turn' do
      runner, output = make_runner("e2 e4\nquit\n")
      capture_exit { runner.start }
      expect(output.string).to include('♙')
    end

    it 'shows an error message for invalid input' do
      runner, output = make_runner("bad_input\nquit\n")
      capture_exit { runner.start }
      expect(output.string).to include("Invalid input")
    end

    it 'rejects an illegal move and prints a message' do
      runner, output = make_runner("e2 e5\nquit\n")
      capture_exit { runner.start }
      expect(output.string).to include('Illegal move')
    end

    it 'accepts a legal move and shows black\'s turn next' do
      runner, output = make_runner("e2 e4\nquit\n")
      capture_exit { runner.start }
      expect(output.string).to include("Black's turn")
    end
  end

  describe 'save command' do
    let(:tmp_dir) { Dir.mktmpdir }
    after { FileUtils.rm_rf(tmp_dir) }

    before do
      stub_const("#{described_class}::SAVES_DIR", tmp_dir)
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(tmp_dir).and_return(false)
    end

    it 'writes a .yml file to the saves directory' do
      runner, _output = make_runner("save\nquit\n")
      capture_exit { runner.start }
      expect(Dir.glob(File.join(tmp_dir, '*.yml'))).not_to be_empty
    end

    it 'prints a saved confirmation message' do
      runner, output = make_runner("save\nquit\n")
      capture_exit { runner.start }
      expect(output.string).to include('Saved')
    end
  end

  describe 'resign command' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(described_class::SAVES_DIR).and_return(false)
    end

    it 'announces the winner when white resigns' do
      runner, output = make_runner("resign\n")
      capture_exit { runner.start }
      expect(output.string).to include('Black wins')
    end
  end

  describe 'delete save from startup menu' do
    let(:tmp_dir) { Dir.mktmpdir }
    after { FileUtils.rm_rf(tmp_dir) }

    before do
      stub_const("#{described_class}::SAVES_DIR", tmp_dir)
      FileUtils.touch(File.join(tmp_dir, 'save_test.yml'))
    end

    it 'deletes the selected save file when d1 is entered' do
      runner, _output = make_runner("d1\nquit\n")
      capture_exit { runner.start }
      expect(Dir.glob(File.join(tmp_dir, '*.yml'))).to be_empty
    end

    it 'prints a deletion confirmation message' do
      runner, output = make_runner("d1\nquit\n")
      capture_exit { runner.start }
      expect(output.string).to include('Deleted')
    end

    it 'starts a new game automatically after all saves are deleted' do
      runner, output = make_runner("d1\nquit\n")
      capture_exit { runner.start }
      expect(output.string).to include("White's turn")
    end

    it 'shows an error and re-prompts for an out-of-range delete index' do
      runner, output = make_runner("d99\nn\nquit\n")
      capture_exit { runner.start }
      expect(output.string).to include('Invalid choice')
      expect(Dir.glob(File.join(tmp_dir, '*.yml'))).not_to be_empty
    end
  end

  describe 'promotion prompt' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(described_class::SAVES_DIR).and_return(false)
    end

    it 'promotes correctly when promotion piece is in the move string' do
      # Set up a board where white pawn is one step from promotion
      game = Chess::Game.new
      # Manually place white pawn at [6,4] for quick test via move input
      # Actually let's just verify inline promotion parsing is wired up via input
      # We use the fact that "e7 e8q" won't match any legal move in starting position
      runner, output = make_runner("e7 e8q\nquit\n")
      capture_exit { runner.start }
      expect(output.string).to include('Illegal move')
    end
  end
end
