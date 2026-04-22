import { jest, describe, it, expect, beforeEach } from '@jest/globals';
import { App } from '../../frontend/js/app.js';

// ------------------------------------------------------------------ //
// Helpers                                                             //
// ------------------------------------------------------------------ //

function makeState(overrides = {}) {
  return {
    board: { e2: { type: 'pawn', color: 'white' } },
    turn: 'white',
    status: 'playing',
    legal_moves: { e2: ['e3', 'e4'] },
    last_move: null,
    message: "White's turn.",
    ...overrides,
  };
}

function makeMockApi(stateOverrides = {}) {
  const defaultState = makeState(stateOverrides);
  return {
    createGame: jest.fn().mockResolvedValue({ game_id: 'game-1', state: defaultState }),
    makeMove:   jest.fn().mockResolvedValue({ status: 'playing', state: makeState({ turn: 'black' }) }),
    saveGame:   jest.fn().mockResolvedValue({ saved: 'save.yml' }),
    resign:     jest.fn().mockResolvedValue({ message: 'White resigns. Black wins!' }),
    listSaves:  jest.fn().mockResolvedValue({ saves: [] }),
    loadSave:   jest.fn().mockResolvedValue({ game_id: 'loaded', state: makeState() }),
    deleteSave: jest.fn().mockResolvedValue({ deleted: 'save.yml' }),
  };
}

function makeElements() {
  const boardEl       = document.createElement('div');
  const statusEl      = document.createElement('div');
  const historyEl     = document.createElement('ol');
  const promotionModal = document.createElement('div');
  const gameOverModal  = document.createElement('div');
  const gameOverMsg    = document.createElement('p');
  const newGameBtn     = document.createElement('button');
  const saveBtn        = document.createElement('button');
  const resignBtn      = document.createElement('button');

  promotionModal.innerHTML = `
    <button data-piece="queen">Queen</button>
    <button data-piece="rook">Rook</button>
    <button data-piece="bishop">Bishop</button>
    <button data-piece="knight">Knight</button>
  `;
  const promotionBtns = promotionModal.querySelectorAll('[data-piece]');

  return { boardEl, statusEl, historyEl, promotionModal, promotionBtns,
           gameOverModal, gameOverMsg, newGameBtn, saveBtn, resignBtn };
}

function makeApp(apiOverrides = {}, stateOverrides = {}) {
  const api = { ...makeMockApi(stateOverrides), ...apiOverrides };
  return { app: new App(makeElements(), api), api };
}

// ------------------------------------------------------------------ //
// Tests                                                               //
// ------------------------------------------------------------------ //

describe('App#start', () => {
  it('calls createGame and renders 64 squares', async () => {
    const { app, api } = makeApp();
    await app.start();
    expect(api.createGame).toHaveBeenCalledTimes(1);
    expect(app.boardEl.querySelectorAll('.square')).toHaveLength(64);
  });

  it('stores the game id and initial state', async () => {
    const { app } = makeApp();
    await app.start();
    expect(app.gameId).toBe('game-1');
    expect(app.state).not.toBeNull();
  });

  it('resets move history on new game', async () => {
    const { app } = makeApp();
    await app.start();
    app.moveHistory.push('e2→e4'); // simulate a move
    await app.start();
    expect(app.moveHistory).toHaveLength(0);
  });

  it('hides the game-over modal', async () => {
    const { app } = makeApp();
    app.gameOverModal.style.display = 'flex'; // simulate open modal
    await app.start();
    expect(app.gameOverModal.style.display).toBe('none');
  });

  it('updates the status bar text', async () => {
    const { app } = makeApp();
    await app.start();
    expect(app.statusEl.textContent).toBe("White's turn.");
  });
});

describe('App#handleSquareClick — piece selection', () => {
  let app;

  beforeEach(async () => {
    ({ app } = makeApp());
    await app.start();
  });

  it('selects an own piece and shows legal-target squares', () => {
    app.handleSquareClick('e2');
    expect(app.selectedSquare).toBe('e2');
    expect(app.uiState).toBe('piece_selected');
    expect(app.boardEl.querySelectorAll('.legal-target').length).toBeGreaterThan(0);
  });

  it('does nothing when clicking an empty square in idle state', () => {
    app.handleSquareClick('e5'); // empty, no piece
    expect(app.selectedSquare).toBeNull();
    expect(app.uiState).toBe('idle');
  });

  it('deselects when clicking a non-target square after selection', () => {
    app.handleSquareClick('e2'); // select
    app.handleSquareClick('d5'); // not a legal target
    expect(app.selectedSquare).toBeNull();
    expect(app.uiState).toBe('idle');
  });

  it('re-selects when clicking a different own piece', () => {
    app.state = makeState({
      board: {
        e2: { type: 'pawn', color: 'white' },
        d2: { type: 'pawn', color: 'white' },
      },
      legal_moves: { e2: ['e3', 'e4'], d2: ['d3', 'd4'] },
    });
    app.handleSquareClick('e2');
    app.handleSquareClick('d2');
    expect(app.selectedSquare).toBe('d2');
  });
});

describe('App#handleSquareClick — move submission', () => {
  it('calls makeMove when clicking a legal target', async () => {
    const { app, api } = makeApp();
    await app.start();
    app.handleSquareClick('e2');
    await app.handleSquareClick('e4'); // legal target → triggers _submitMove
    expect(api.makeMove).toHaveBeenCalledWith('game-1', 'e2', 'e4', null);
  });

  it('resets selection after a move', async () => {
    const { app } = makeApp();
    await app.start();
    app.handleSquareClick('e2');
    await app.handleSquareClick('e4');
    expect(app.selectedSquare).toBeNull();
    expect(app.uiState).toBe('idle');
  });

  it('appends to move history', async () => {
    const { app } = makeApp();
    await app.start();
    app.handleSquareClick('e2');
    await app.handleSquareClick('e4');
    expect(app.moveHistory).toContain('e2→e4');
  });

  it('does nothing when game is already over', async () => {
    const { app, api } = makeApp({}, { status: 'checkmate' });
    await app.start();
    app.handleSquareClick('e2');
    expect(api.makeMove).not.toHaveBeenCalled();
  });
});

describe('App — pawn promotion', () => {
  it('shows promotion modal when pawn reaches back rank', async () => {
    const { app } = makeApp();
    await app.start();
    app.state = makeState({
      board: { e7: { type: 'pawn', color: 'white' } },
      legal_moves: { e7: ['e8'] },
    });
    app.handleSquareClick('e7');
    app.handleSquareClick('e8');
    expect(app.uiState).toBe('awaiting_promotion');
    expect(app.promotionModal.style.display).toBe('flex');
  });

  it('submits move with chosen promotion piece', async () => {
    const { app, api } = makeApp();
    await app.start();
    app.state = makeState({
      board: { e7: { type: 'pawn', color: 'white' } },
      legal_moves: { e7: ['e8'] },
    });
    app.handleSquareClick('e7');
    app.handleSquareClick('e8');
    await app._handlePromotion('queen');
    expect(api.makeMove).toHaveBeenCalledWith('game-1', 'e7', 'e8', 'queen');
    expect(app.promotionModal.style.display).toBe('none');
  });
});

describe('App — game over', () => {
  it('shows game-over modal when status is checkmate', async () => {
    const { app } = makeApp({}, { status: 'checkmate', message: 'Checkmate! Black wins.' });
    await app.start();
    expect(app.gameOverModal.style.display).toBe('flex');
    expect(app.gameOverMsg.textContent).toBe('Checkmate! Black wins.');
  });

  it('shows game-over modal when status is stalemate', async () => {
    const { app } = makeApp({}, { status: 'stalemate', message: "Stalemate! It's a draw." });
    await app.start();
    expect(app.gameOverModal.style.display).toBe('flex');
  });
});
