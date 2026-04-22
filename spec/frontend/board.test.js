import { describe, it, expect, beforeEach } from '@jest/globals';
import { render } from '../../frontend/js/board.js';

function makeState(overrides = {}) {
  return {
    board: {},
    turn: 'white',
    status: 'playing',
    legal_moves: {},
    last_move: null,
    message: "White's turn.",
    ...overrides,
  };
}

describe('render', () => {
  let container;

  beforeEach(() => { container = document.createElement('div'); });

  describe('grid structure', () => {
    it('creates exactly 64 squares', () => {
      render(container, makeState());
      expect(container.querySelectorAll('.square')).toHaveLength(64);
    });

    it('assigns 32 light and 32 dark squares', () => {
      render(container, makeState());
      const squares = container.querySelectorAll('.square');
      const light = [...squares].filter(s => s.classList.contains('light'));
      const dark  = [...squares].filter(s => s.classList.contains('dark'));
      expect(light).toHaveLength(32);
      expect(dark).toHaveLength(32);
    });

    it('renders a1 as a dark square', () => {
      render(container, makeState());
      expect(container.querySelector('[data-square="a1"]').classList).toContain('dark');
    });

    it('renders b1 as a light square', () => {
      render(container, makeState());
      expect(container.querySelector('[data-square="b1"]').classList).toContain('light');
    });

    it('renders h8 as a dark square', () => {
      render(container, makeState());
      expect(container.querySelector('[data-square="h8"]').classList).toContain('dark');
    });
  });

  describe('pieces', () => {
    it('renders white pawn symbol ♙', () => {
      const state = makeState({ board: { e2: { type: 'pawn', color: 'white' } } });
      render(container, state);
      expect(container.querySelector('[data-square="e2"] .piece').textContent).toBe('♙');
    });

    it('renders black king symbol ♚', () => {
      const state = makeState({ board: { e8: { type: 'king', color: 'black' } } });
      render(container, state);
      expect(container.querySelector('[data-square="e8"] .piece').textContent).toBe('♚');
    });

    it('renders white queen symbol ♕', () => {
      const state = makeState({ board: { d1: { type: 'queen', color: 'white' } } });
      render(container, state);
      expect(container.querySelector('[data-square="d1"] .piece').textContent).toBe('♕');
    });

    it('does not render a piece element on empty squares', () => {
      render(container, makeState({ board: {} }));
      expect(container.querySelector('.piece')).toBeNull();
    });
  });

  describe('selection and legal targets', () => {
    it('adds selected class to the chosen square', () => {
      render(container, makeState(), 'e2');
      expect(container.querySelector('[data-square="e2"]').classList).toContain('selected');
    });

    it('does not add selected to other squares', () => {
      render(container, makeState(), 'e2');
      expect(container.querySelector('[data-square="d4"]').classList).not.toContain('selected');
    });

    it('adds legal-target class to target squares', () => {
      render(container, makeState(), 'e2', ['e3', 'e4']);
      expect(container.querySelector('[data-square="e3"]').classList).toContain('legal-target');
      expect(container.querySelector('[data-square="e4"]').classList).toContain('legal-target');
    });

    it('does not mark non-target squares as legal-target', () => {
      render(container, makeState(), 'e2', ['e3', 'e4']);
      expect(container.querySelector('[data-square="d4"]').classList).not.toContain('legal-target');
    });
  });

  describe('last-move highlight', () => {
    it('marks from and to squares with last-move class', () => {
      const state = makeState({ last_move: { from: 'e2', to: 'e4' } });
      render(container, state);
      expect(container.querySelector('[data-square="e2"]').classList).toContain('last-move');
      expect(container.querySelector('[data-square="e4"]').classList).toContain('last-move');
    });

    it('does not add last-move when last_move is null', () => {
      render(container, makeState({ last_move: null }));
      expect(container.querySelector('.last-move')).toBeNull();
    });
  });

  describe('check highlight', () => {
    it('adds in-check class to the current player king when status is check', () => {
      const state = makeState({
        status: 'check',
        turn: 'white',
        board: { e1: { type: 'king', color: 'white' } },
      });
      render(container, state);
      expect(container.querySelector('[data-square="e1"]').classList).toContain('in-check');
    });

    it('does not add in-check when status is playing', () => {
      const state = makeState({
        status: 'playing',
        board: { e1: { type: 'king', color: 'white' } },
      });
      render(container, state);
      expect(container.querySelector('[data-square="e1"]').classList).not.toContain('in-check');
    });

    it('does not add in-check to the opponent king', () => {
      const state = makeState({
        status: 'check',
        turn: 'white',
        board: { e8: { type: 'king', color: 'black' } },
      });
      render(container, state);
      expect(container.querySelector('[data-square="e8"]').classList).not.toContain('in-check');
    });
  });
});
