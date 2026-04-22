# Chess

A two-player chess engine written in pure Ruby, with a terminal CLI and a REST API.  
Final capstone project for [The Odin Project — Ruby course](https://www.theodinproject.com/lessons/ruby-chess).

```
  a  b  c  d  e  f  g  h
8 ♜  ♞  ♝  ♛  ♚  ♝  ♞  ♜  8
7 ♟  ♟  ♟  ♟  ♟  ♟  ♟  ♟  7
6                            6
5                            5
4                            4
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
- Browser UI — clickable board, promotion picker, move history, game-over modal
- Save / load / delete games (YAML, stored in `saves/`)
- Resign command
- REST API (Sinatra) with full OpenAPI spec (`docs/openapi.yml`)
- 277 RSpec + 46 Jest examples covering every layer of the stack

## Requirements

- Ruby ≥ 3.0
- Bundler
- Node.js ≥ 18 (frontend tests only)

## Setup

```bash
git clone <repo-url>
cd odin_chess
bundle install
npm install     # only needed to run frontend tests
```

## Play (CLI)

```bash
ruby bin/chess
```

On startup, if saved games exist you will be asked whether to load one, start fresh, or delete a save.

### CLI input format

| Input | Action |
|-------|--------|
| `e2 e4` | Move piece from e2 to e4 |
| `e2e4` | Same, compact form |
| `e7 e8q` | Move + promote to queen (`q` `r` `b` `n`) |
| `save` | Save current game to `saves/` |
| `resign` | Forfeit — opponent wins |
| `quit` | Exit the program |

If you move a pawn to the back rank without a promotion suffix, you will be prompted to choose a piece.

### Startup menu

| Input | Action |
|-------|--------|
| `1`–`n` | Load save number n |
| `n` / Enter | Start new game |
| `d1`–`dn` | Delete save number n |

## Browser UI

```bash
bundle exec rackup -s webrick -q   # starts server at http://localhost:9292
```

Open `http://localhost:9292` to play in the browser. Click a piece to select it — legal target squares are highlighted. Click a target to move. Pawn promotion shows a picker; castling and en passant are handled automatically.

## REST API

```bash
bundle exec rackup -s webrick -q   # same server, API at http://localhost:9292
```

Full endpoint reference: [`docs/openapi.yml`](docs/openapi.yml)

### Quick reference

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/games` | Create a new game → `{ game_id, state }` |
| `GET` | `/games/:id` | Get current board state |
| `POST` | `/games/:id/moves` | Submit a move |
| `POST` | `/games/:id/save` | Save game to file |
| `DELETE` | `/games/:id` | Resign |
| `GET` | `/games/saved` | List save files |
| `POST` | `/games/load/:save_name` | Load from save → new `game_id` |
| `DELETE` | `/games/saved/:save_name` | Delete a save file |

**Submit a move:**

```bash
curl -X POST http://localhost:9292/games/<id>/moves \
  -H 'Content-Type: application/json' \
  -d '{"from":"e2","to":"e4"}'

# Pawn promotion
curl -X POST http://localhost:9292/games/<id>/moves \
  -H 'Content-Type: application/json' \
  -d '{"from":"e7","to":"e8","promotion":"queen"}'
```

The move type (castling, en passant) is inferred automatically — you never need to specify it.

## Running Tests

```bash
bundle exec rspec                                          # all 277 Ruby examples
bundle exec rspec spec/chess/move_validator_spec.rb        # single file
bundle exec rspec spec/chess/pieces/pawn_spec.rb:45        # single example
bundle exec rspec --format documentation                   # verbose output

npm run test:frontend                                      # all 46 JS examples (Jest)
```

## Architecture

Chess logic lives entirely in `lib/chess/` with zero I/O. The CLI and Web API are independent adapters on top — both call only `Game#make_move` and `Game#legal_moves`.

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

app/
├── game_store.rb        # In-memory UUID→Game store with 30-min TTL eviction
└── api.rb               # Sinatra REST API + static file serving

frontend/
├── index.html           # Page shell — wires App with DOM elements
├── css/board.css        # Board layout, square colours, highlight styles
└── js/
    ├── api.js           # fetch wrappers for all REST endpoints
    ├── board.js         # render(containerEl, state, …) → pure DOM rebuild
    └── app.js           # App class: idle → piece_selected → awaiting_promotion
```

### Data flow — CLI

```
User types "e2 e4"
  → InputParser#parse       → { type: :move, from: [1,4], to: [3,4] }
  → Runner#do_move          → finds legal Move from Game#legal_moves
  → Game#make_move          → MoveValidator validates + applies, status updated
  → Runner#print_board      → Renderer#render → ANSI string to stdout
```

### Data flow — API

```
POST /games/:id/moves  { from: "e2", to: "e4" }
  → API#post            → matches from/to against Game#legal_moves
  → Game#make_move      → MoveValidator validates + applies, status updated
  → API#build_state     → serialises board + legal_moves → JSON response
```

### Data flow — Browser UI

```
User clicks a square
  → App#handleSquareClick   → updates selectedSquare / uiState
  → board.js#render         → rebuilds DOM, adds CSS classes
  → (on legal target click)
  → Api#makeMove            → POST /games/:id/moves
  → App#_refresh            → re-renders board with new state
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
├── bin/chess            # CLI executable entry point
├── config.ru            # Rack entry point (rackup)
├── package.json         # JS dev dependencies (Jest)
├── lib/
│   ├── chess.rb         # Requires all engine files
│   └── chess/           # Engine + CLI adapter (see above)
├── app/                 # Web API adapter
├── frontend/            # Browser UI (served by Sinatra)
│   ├── index.html
│   ├── css/board.css
│   └── js/              # api.js, board.js, app.js
├── spec/
│   ├── chess/           # Engine + CLI unit tests (RSpec)
│   │   ├── pieces/
│   │   └── cli/
│   ├── app/             # Web API unit tests (RSpec)
│   ├── frontend/        # Browser UI unit tests (Jest)
│   └── integration/     # End-to-end tests (CLI + HTTP)
├── saves/               # Game saves written here (YAML)
├── CHANGELOG.md         # Notable changes per session
└── docs/
    ├── spec.md          # Functional requirements
    ├── design.md        # Architecture decisions
    ├── testing.md       # Test catalogue
    └── openapi.yml      # OpenAPI 3.0 API specification
```
