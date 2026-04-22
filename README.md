# Chess

A two-player chess engine for the terminal, written in pure Ruby.  
Final capstone project for [The Odin Project — Ruby course](https://www.theodinproject.com/lessons/ruby-chess).

```
  a  b  c  d  e  f  g  h
8 ♜  ♞  ♝  ♛  ♚  ♝  ♞  ♜  8
7 ♟  ♟  ♟  ♟  ♟  ♟  ♟  ♟  7
6                            6
5                            5
4                            6
3                            3
2 ♙  ♙  ♙  ♙  ♙  ♙  ♙  ♙  2
1 ♖  ♘  ♗  ♕  ♔  ♗  ♘  ♖  1
  a  b  c  d  e  f  g  h
```

## Features

- All standard chess rules: castling, en passant, pawn promotion
- Check, checkmate, and stalemate detection
- Illegal-move prevention — moves that leave your own king in check are rejected
- ANSI-colour board with Unicode pieces, last-move highlight, and check highlight
- Save / load games (YAML, stored in `saves/`)
- Resign command
- 232 RSpec examples covering every layer of the stack

## Requirements

- Ruby ≥ 3.0
- Bundler

## Setup

```bash
git clone <repo-url>
cd odin_chess
bundle install
```

## Play

```bash
ruby bin/chess
```

On startup, if saved games exist you will be asked whether to load one or start fresh.

### Input format

| Input | Action |
|-------|--------|
| `e2 e4` | Move piece from e2 to e4 |
| `e2e4` | Same, compact form |
| `e7 e8q` | Move + promote to queen (`q` `r` `b` `n`) |
| `save` | Save current game to `saves/` |
| `resign` | Forfeit — opponent wins |
| `quit` | Exit the program |

If you move a pawn to the back rank without a promotion suffix, you will be prompted to choose a piece.

## Running Tests

```bash
bundle exec rspec                                          # all 232 examples
bundle exec rspec spec/chess/move_validator_spec.rb        # single file
bundle exec rspec spec/chess/pieces/pawn_spec.rb:45        # single example
bundle exec rspec --format documentation                   # verbose output
```

## Architecture

Chess logic lives entirely in `lib/chess/` with zero I/O. The CLI in `lib/chess/cli/` is a thin adapter on top — it handles rendering and user input but contains no chess rules.

```
lib/chess/
├── move.rb              # Move value object (from, to, type, promotion_piece)
├── board.rb             # 8×8 grid, en_passant_target, deep_clone
├── pieces/
│   ├── piece.rb         # Abstract base — slide_moves, step_moves helpers
│   ├── king.rb          # Includes castling move generation
│   ├── queen.rb
│   ├── rook.rb
│   ├── bishop.rb
│   ├── knight.rb
│   └── pawn.rb          # Double-push, en passant, 4 promotion moves
├── move_validator.rb    # legal_moves, in_check?, apply_move!, checkmate?, stalemate?
├── game.rb              # Turn loop, make_move (single public entry point), status machine
├── serializer.rb        # YAML save/load — plain-hash round-trip, no Marshal
└── cli/
    ├── renderer.rb      # ANSI board rendering
    ├── input_parser.rb  # "e2 e4" / "e7 e8q" / commands → structured result
    └── runner.rb        # Game loop — glues renderer, parser, and Game together
```

### Data flow for a move

```
User types "e2 e4"
  → InputParser#parse       → { type: :move, from: [1,4], to: [3,4] }
  → Runner#do_move          → finds legal Move from Game#legal_moves
  → Game#make_move          → MoveValidator validates + applies, status updated
  → Runner#print_board      → Renderer#render → ANSI string to stdout
```

### Coordinate system

All positions are `[rank, file]` (both 0-indexed):

| Array | Notation | Notes |
|-------|----------|-------|
| `[0, 4]` | e1 | White king start |
| `[7, 4]` | e8 | Black king start |
| `[1, 4]` | e2 | White e-pawn start |
| `[6, 4]` | e7 | Black e-pawn start |

`rank 0` = white's first rank; `file 0` = a-file.

## Project Structure

```
odin_chess/
├── bin/chess            # Executable entry point
├── lib/
│   ├── chess.rb         # Requires all engine files
│   └── chess/           # Engine + CLI adapter (see above)
├── spec/
│   ├── chess/           # Unit tests — engine and CLI
│   │   ├── pieces/
│   │   └── cli/
│   └── integration/     # End-to-end tests (input → engine → renderer)
├── saves/               # Game saves written here (YAML)
└── docs/
    ├── spec.md          # Functional requirements
    ├── design.md        # Architecture decisions
    └── testing.md       # Test catalogue
```
