import { jest, describe, it, expect, afterEach } from '@jest/globals';
import { Api } from '../../frontend/js/api.js';

function mockFetch(data, status = 200) {
  global.fetch = jest.fn().mockResolvedValue({
    ok: status >= 200 && status < 300,
    status,
    json: () => Promise.resolve(data),
  });
}

describe('Api', () => {
  afterEach(() => { jest.resetAllMocks(); });

  describe('createGame', () => {
    it('POSTs to /games', async () => {
      mockFetch({ game_id: 'abc', state: {} });
      await Api.createGame();
      expect(fetch).toHaveBeenCalledWith('/games', expect.objectContaining({ method: 'POST' }));
    });

    it('returns the response data', async () => {
      mockFetch({ game_id: 'abc', state: { turn: 'white' } });
      const result = await Api.createGame();
      expect(result.game_id).toBe('abc');
    });
  });

  describe('makeMove', () => {
    it('POSTs to /games/:id/moves with from/to body', async () => {
      mockFetch({ status: 'playing', state: {} });
      await Api.makeMove('g1', 'e2', 'e4', null);
      expect(fetch).toHaveBeenCalledWith(
        '/games/g1/moves',
        expect.objectContaining({ method: 'POST', body: JSON.stringify({ from: 'e2', to: 'e4' }) })
      );
    });

    it('includes promotion field when provided', async () => {
      mockFetch({ status: 'playing', state: {} });
      await Api.makeMove('g1', 'e7', 'e8', 'queen');
      const body = JSON.parse(fetch.mock.calls[0][1].body);
      expect(body.promotion).toBe('queen');
    });

    it('omits promotion field when not provided', async () => {
      mockFetch({ status: 'playing', state: {} });
      await Api.makeMove('g1', 'e2', 'e4', null);
      const body = JSON.parse(fetch.mock.calls[0][1].body);
      expect(body).not.toHaveProperty('promotion');
    });
  });

  describe('resign', () => {
    it('DELETEs /games/:id', async () => {
      mockFetch({ message: 'White resigns. Black wins!' });
      await Api.resign('g1');
      expect(fetch).toHaveBeenCalledWith('/games/g1', expect.objectContaining({ method: 'DELETE' }));
    });
  });

  describe('saveGame', () => {
    it('POSTs to /games/:id/save', async () => {
      mockFetch({ saved: 'save.yml' });
      await Api.saveGame('g1');
      expect(fetch).toHaveBeenCalledWith('/games/g1/save', expect.objectContaining({ method: 'POST' }));
    });
  });

  describe('listSaves', () => {
    it('GETs /games/saved', async () => {
      mockFetch({ saves: [] });
      await Api.listSaves();
      expect(fetch).toHaveBeenCalledWith('/games/saved', expect.objectContaining({ method: 'GET' }));
    });
  });

  describe('loadSave', () => {
    it('POSTs to /games/load/:name', async () => {
      mockFetch({ game_id: 'new', state: {} });
      await Api.loadSave('my-save.yml');
      expect(fetch).toHaveBeenCalledWith(
        '/games/load/my-save.yml',
        expect.objectContaining({ method: 'POST' })
      );
    });
  });

  describe('deleteSave', () => {
    it('DELETEs /games/saved/:name', async () => {
      mockFetch({ deleted: 'my-save.yml' });
      await Api.deleteSave('my-save.yml');
      expect(fetch).toHaveBeenCalledWith(
        '/games/saved/my-save.yml',
        expect.objectContaining({ method: 'DELETE' })
      );
    });
  });

  describe('error handling', () => {
    it('throws with status when response is not ok', async () => {
      mockFetch({ error: 'Game not found' }, 404);
      await expect(Api.getGame('bad')).rejects.toMatchObject({ status: 404 });
    });
  });
});
