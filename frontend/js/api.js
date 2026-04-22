const BASE_URL = '';

async function request(path, { method = 'GET', body = null } = {}) {
  const options = { method, headers: { 'Content-Type': 'application/json' } };
  if (body !== null) options.body = JSON.stringify(body);

  const res = await fetch(`${BASE_URL}${path}`, options);
  const data = await res.json();
  if (!res.ok) throw Object.assign(new Error(data.error || 'Request failed'), { status: res.status, data });
  return data;
}

export const Api = {
  createGame:  ()                     => request('/games', { method: 'POST' }),
  getGame:     (id)                   => request(`/games/${id}`),
  makeMove:    (id, from, to, promo)  => {
    const body = { from, to };
    if (promo) body.promotion = promo;
    return request(`/games/${id}/moves`, { method: 'POST', body });
  },
  saveGame:    (id)                   => request(`/games/${id}/save`, { method: 'POST' }),
  resign:      (id)                   => request(`/games/${id}`, { method: 'DELETE' }),
  listSaves:   ()                     => request('/games/saved'),
  loadSave:    (name)                 => request(`/games/load/${name}`, { method: 'POST' }),
  deleteSave:  (name)                 => request(`/games/saved/${name}`, { method: 'DELETE' }),
};
