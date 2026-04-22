# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle install          # install dependencies
bundle exec rspec       # run all tests
bundle exec rspec spec/chess/move_validator_spec.rb          # run a single spec file
bundle exec rspec spec/chess/pieces/pawn_spec.rb:45          # run a single example by line
bundle exec rspec --format documentation                     # verbose output (default via .rspec)
```

## Architecture

This is a pure-Ruby CLI chess engine. The single most important design rule: **chess logic lives in `lib/chess/`, with zero I/O**. CLI and future Web API are adapters on top.

### Coordinate system

All positions are `[rank, file]` (both 0-indexed):
- `rank 0` = white's first rank (rank 1 in chess notation); `rank 7` = black's first rank
- `file 0` = a-file; `file 7` = h-file
- White pieces start at ranks 0–1, black at ranks 6–7

### Key classes and responsibilities

**`Move`** — value object with `from`, `to`, `type` (`:normal | :castle_kingside | :castle_queenside | :en_passant | :promotion`), and optional `promotion_piece`. `==` is defined so moves can be matched against the legal-moves list.

**`Pieces::Piece`** (abstract) — provides `slide_moves` and `step_moves` helpers used by all subclasses. `piece.moves(board)` returns **pseudo-legal** moves only (no check filtering). Each piece is responsible solely for its movement vectors.

**`Board`** — manages the 8×8 grid and `en_passant_target`. `deep_clone` is the workhorse: it creates a fully independent copy used by `MoveValidator` to simulate moves without touching the real board.

**`MoveValidator`** — the rule-enforcement layer. `legal_moves(color, board)` calls `piece.moves(board)` for every piece, clones the board, applies each move via `apply_move!`, and discards any move where `in_check?` is still true after. All special-move semantics (castling rook teleport, en passant pawn removal, promotion piece swap) are implemented in `apply_move!` here, not in the pieces themselves.

**`Game`** — turn loop and status machine. `make_move(move)` is the single public entry point for both CLI and Web API. It validates the move against `legal_moves`, delegates to `MoveValidator#apply_move!`, switches turns, and recomputes status (`:playing | :check | :checkmate | :stalemate`).

**`Serializer`** — converts `Game` to a plain Ruby hash (all-string keys, symbols serialized as strings) and writes YAML. On load, reconstructs every object from the hash. Avoids Marshal to prevent version-coupling.

### Data flow for a move

```
caller submits Move
  → Game#make_move
      → MoveValidator#legal_moves  (uses Board#deep_clone + Piece#moves per piece)
      → MoveValidator#apply_move!  (mutates real board)
      → Game#update_status         (calls checkmate?/stalemate?/in_check?)
  → returns { success:, status:, message: }
```

### Pawn promotions

`Pawn#moves` generates **4 separate Move objects** for each promotion (one per `promotion_piece` value). The caller must submit a move with an explicit `promotion_piece`; unmatched moves are rejected as illegal.

### En passant state

`Board#en_passant_target` holds the capture square (the square the pawn skipped over). `MoveValidator#apply_move!` sets it after a double-push and clears it after any other move. `Pawn#moves` reads it directly from the board object.
