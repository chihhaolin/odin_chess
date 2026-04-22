# Changelog

## [Unreleased] — 2026-04-22

### Changed — Dark board colour scheme

Replaced the classic wood palette with a dark slate-blue theme for better readability.

#### `frontend/js/board.js`

Piece `<span>` now carries the piece colour as an extra CSS class (`piece white` / `piece black`),
enabling per-colour styling in CSS without touching the render logic.

```js
// before
span.className = 'piece';

// after
span.className = `piece ${piece.color}`;
```

#### `frontend/css/board.css`

| Element | Before | After |
|---------|--------|-------|
| Light square | `#f0d9b5` (cream) | `#7c9ab5` (steel blue) |
| Dark square | `#b58863` (wood brown) | `#3a5570` (dark blue-grey) |
| White pieces | inherited `#e0e0e0` — invisible on light squares | `#f5f5f5` + 4-direction black text-shadow |
| Black pieces | same as white — indistinguishable | `#111827` + soft blue-white glow |
| Selected highlight | `#7fc97f` | `#48c774` (brighter green) |

Root problem: both piece colours previously inherited the body text colour (`#e0e0e0`),
making them look identical and nearly invisible on light squares.

---

### Fixed — Server startup (Phase 4 hotfix)

Three issues discovered when first running `rackup` after Phase 4 was merged:

#### 1. `public_folder` path one level too deep (`app/api.rb`)

`__dir__` inside `app/api.rb` resolves to `<project>/app/`.  
`'../../frontend'` therefore pointed two levels up — outside the project — instead of `<project>/frontend/`.

```ruby
# before
set :public_folder, File.expand_path('../../frontend', __dir__)

# after
set :public_folder, File.expand_path('../frontend', __dir__)
```

Symptom: `GET /` returned 404 even though the route existed.

#### 2. Missing web server adapter (`Gemfile`, `config.ru`)

`rack-test` (used by all existing specs) runs in-process and needs no real server.  
Running `rackup` for the first time exposed that no server adapter was installed.

```ruby
# Gemfile — added
gem 'webrick', '~> 1.8'

# config.ru — added
require 'webrick'
```

Symptom: `Couldn't find handler for: puma, thin, falcon, webrick (LoadError)`.

#### 3. System `rackup` vs bundled gems conflict

The system-installed `rackup` binary loaded `rack-2.2.23`, which conflicted with
`sinatra ~> 3.0` (requires `rack >= 2.x` but the system had a gem activation clash).  
The fix is to always invoke through Bundler.

```bash
# before (broken)
rackup

# after
bundle exec rackup -s webrick -q
```

Updated `CLAUDE.md` and `README.md` to reflect the correct startup command.

---

### Root cause note

All existing tests use `rack-test` (in-process HTTP) or jsdom (browser mock), so none of them exercise real server startup. The `api_spec.rb` also overrides `public_folder` with a temp dir in `before` blocks, masking the wrong path. A server-level smoke test would catch this class of bug — see discussion in commit for details.
