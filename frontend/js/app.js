import { Api as DefaultApi } from './api.js';
import { render } from './board.js';

// State machine states
const IDLE       = 'idle';
const SELECTED   = 'piece_selected';
const PROMOTION  = 'awaiting_promotion';

export class App {
  // elements — DOM node references (all optional via ?.)
  // api      — injectable Api object (defaults to the real fetch-based Api)
  constructor(elements, api = DefaultApi) {
    this.api = api;
    Object.assign(this, elements);

    this.gameId           = null;
    this.state            = null;
    this.selectedSquare   = null;
    this.pendingPromotion = null;
    this.uiState          = IDLE;
    this.moveHistory      = [];

    this._bindButtons();
  }

  // ------------------------------------------------------------------ //
  // Public API                                                          //
  // ------------------------------------------------------------------ //

  async start() {
    if (this.gameOverModal) this.gameOverModal.style.display = 'none';
    const data = await this.api.createGame();
    this.gameId      = data.game_id;
    this.state       = data.state;
    this.moveHistory = [];
    this.selectedSquare   = null;
    this.pendingPromotion = null;
    this.uiState          = IDLE;
    this._refresh();
  }

  // Returns a Promise when an async operation is initiated (for testability)
  handleSquareClick(square) {
    if (!this.state) return;
    if (this.state.status === 'checkmate' || this.state.status === 'stalemate') return;
    if (this.uiState === PROMOTION) return;

    const piece     = this.state.board[square];
    const isOwnPiece = piece && piece.color === this.state.turn;

    if (isOwnPiece) {
      this.selectedSquare = square;
      this.uiState        = SELECTED;
      this._refresh();
      return;
    }

    if (this.uiState === SELECTED) {
      const targets = this.state.legal_moves[this.selectedSquare] || [];

      if (targets.includes(square)) {
        const movingPiece = this.state.board[this.selectedSquare];
        const isPromo = movingPiece?.type === 'pawn' &&
          ((movingPiece.color === 'white' && square[1] === '8') ||
           (movingPiece.color === 'black' && square[1] === '1'));

        if (isPromo) {
          this.pendingPromotion = { from: this.selectedSquare, to: square };
          this.uiState          = PROMOTION;
          this._showPromotionModal();
        } else {
          return this._submitMove(this.selectedSquare, square, null);
        }
      } else {
        this.selectedSquare = null;
        this.uiState        = IDLE;
        this._refresh();
      }
    }
  }

  // ------------------------------------------------------------------ //
  // Internal                                                            //
  // ------------------------------------------------------------------ //

  _bindButtons() {
    this.newGameBtn?.addEventListener('click', () => this.start());
    this.saveBtn?.addEventListener('click',    () => this._handleSave());
    this.resignBtn?.addEventListener('click',  () => this._handleResign());
    this.promotionBtns?.forEach(btn => {
      btn.addEventListener('click', () => this._handlePromotion(btn.dataset.piece));
    });
  }

  _refresh() {
    const targets = this.selectedSquare
      ? (this.state.legal_moves[this.selectedSquare] || [])
      : [];

    render(this.boardEl, this.state, this.selectedSquare, targets);
    this._updateStatus();
    this._updateHistory();
    this._attachSquareHandlers();

    if (this.state.status === 'checkmate' || this.state.status === 'stalemate') {
      this._showGameOver();
    }
  }

  _updateStatus() {
    if (this.statusEl) this.statusEl.textContent = this.state.message;
  }

  _updateHistory() {
    if (!this.historyEl) return;
    this.historyEl.innerHTML = '';
    this.moveHistory.forEach((entry, i) => {
      const li = document.createElement('li');
      li.textContent = i % 2 === 0 ? `${Math.floor(i / 2) + 1}. ${entry}` : `   ${entry}`;
      this.historyEl.appendChild(li);
    });
  }

  _attachSquareHandlers() {
    this.boardEl?.querySelectorAll('.square').forEach(sq => {
      sq.addEventListener('click', () => this.handleSquareClick(sq.dataset.square));
    });
  }

  async _submitMove(from, to, promotion) {
    try {
      const data = await this.api.makeMove(this.gameId, from, to, promotion);
      const suffix = promotion ? `=${promotion[0].toUpperCase()}` : '';
      this.moveHistory.push(`${from}→${to}${suffix}`);
      this.state = data.state;
    } catch (_) {
      // illegal move — deselect silently
    }
    this.selectedSquare   = null;
    this.pendingPromotion = null;
    this.uiState          = IDLE;
    this._refresh();
  }

  _showPromotionModal() {
    if (this.promotionModal) this.promotionModal.style.display = 'flex';
  }

  _hidePromotionModal() {
    if (this.promotionModal) this.promotionModal.style.display = 'none';
  }

  async _handlePromotion(piece) {
    this._hidePromotionModal();
    if (this.pendingPromotion) {
      await this._submitMove(this.pendingPromotion.from, this.pendingPromotion.to, piece);
    }
  }

  _showGameOver() {
    if (this.gameOverMsg)   this.gameOverMsg.textContent   = this.state.message;
    if (this.gameOverModal) this.gameOverModal.style.display = 'flex';
  }

  async _handleSave() {
    try {
      const data = await this.api.saveGame(this.gameId);
      alert(`Saved: ${data.saved}`);
    } catch (_) {
      alert('Save failed.');
    }
  }

  async _handleResign() {
    if (!confirm('Resign and forfeit the game?')) return;
    try {
      const data = await this.api.resign(this.gameId);
      if (this.gameOverMsg)   this.gameOverMsg.textContent   = data.message;
      if (this.gameOverModal) this.gameOverModal.style.display = 'flex';
    } catch (_) {
      alert('Resign failed.');
    }
  }
}
