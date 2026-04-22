const PIECES = {
  white: { king: '♔', queen: '♕', rook: '♖', bishop: '♗', knight: '♘', pawn: '♙' },
  black: { king: '♚', queen: '♛', rook: '♜', bishop: '♝', knight: '♞', pawn: '♟' },
};

const FILES = 'abcdefgh';

// Pure render: state → DOM. Holds no state of its own.
// containerEl  — the <div id="board"> element
// state        — { board, turn, status, legal_moves, last_move, message }
// selectedSq   — algebraic square string that is selected, or null
// legalTargets — array of target square strings to highlight
export function render(containerEl, state, selectedSq = null, legalTargets = []) {
  containerEl.innerHTML = '';

  for (let rank = 8; rank >= 1; rank--) {
    for (let fi = 0; fi < 8; fi++) {
      const square = `${FILES[fi]}${rank}`;
      const div = document.createElement('div');
      div.className = 'square';
      div.dataset.square = square;

      // a1 (fi=0, rank=1): (0+1)%2=1 → dark; b1 (fi=1, rank=1): (1+1)%2=0 → light
      div.classList.add((fi + rank) % 2 === 1 ? 'dark' : 'light');

      if (state.last_move) {
        if (square === state.last_move.from || square === state.last_move.to) {
          div.classList.add('last-move');
        }
      }

      if (square === selectedSq)             div.classList.add('selected');
      if (legalTargets.includes(square))     div.classList.add('legal-target');

      const piece = state.board[square];
      if (state.status === 'check' && piece?.type === 'king' && piece.color === state.turn) {
        div.classList.add('in-check');
      }

      if (piece) {
        const span = document.createElement('span');
        span.className = `piece ${piece.color}`;
        span.textContent = PIECES[piece.color][piece.type];
        div.appendChild(span);
      }

      containerEl.appendChild(div);
    }
  }
}
