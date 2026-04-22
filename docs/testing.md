# Phase 1 + Phase 2 + Phase 3 + Phase 4 — Test 說明文件

## 測試範圍總覽

### Phase 1 — Chess Engine 單元測試

| 測試檔案 | 測試類別 | 案例數 |
|----------|----------|--------|
| `spec/chess/board_spec.rb` | `Chess::Board` | 28 |
| `spec/chess/pieces/king_spec.rb` | `Chess::Pieces::King` | 18 |
| `spec/chess/pieces/queen_spec.rb` | `Chess::Pieces::Queen` | 13 |
| `spec/chess/pieces/rook_spec.rb` | `Chess::Pieces::Rook` | 11 |
| `spec/chess/pieces/bishop_spec.rb` | `Chess::Pieces::Bishop` | 10 |
| `spec/chess/pieces/knight_spec.rb` | `Chess::Pieces::Knight` | 11 |
| `spec/chess/pieces/pawn_spec.rb` | `Chess::Pieces::Pawn` | 27 |
| `spec/chess/move_validator_spec.rb` | `Chess::MoveValidator` | 37 |
| `spec/chess/game_spec.rb` | `Chess::Game` | 28 |
| `spec/chess/serializer_spec.rb` | `Chess::Serializer` | 11 |
| **Phase 1 小計** | | **194** |

### Phase 2 — CLI Adapter 單元測試

| 測試檔案 | 測試類別 | 案例數 |
|----------|----------|--------|
| `spec/chess/cli/renderer_spec.rb` | `Chess::CLI::Renderer` | 13 |
| `spec/chess/cli/input_parser_spec.rb` | `Chess::CLI::InputParser` | 22 |
| `spec/chess/cli/runner_spec.rb` | `Chess::CLI::Runner` | 13 |
| **Phase 2 小計** | | **48** |

### Phase 3 — Web API 單元測試

| 測試檔案 | 測試類別 | 案例數 |
|----------|----------|--------|
| `spec/app/game_store_spec.rb` | `Chess::GameStore` | 13 |
| `spec/app/api_spec.rb` | `Chess::API` | 24 |
| **Phase 3 小計** | | **37** |

### Phase 4 — Frontend 單元測試（Jest）

| 測試檔案 | 說明 | 案例數 |
|----------|------|--------|
| `spec/frontend/api.test.js`   | `Api` fetch 封裝單元測試       | 11 |
| `spec/frontend/board.test.js` | `render()` 純函式 DOM 測試     | 14 |
| `spec/frontend/app.test.js`   | `App` 狀態機 component 測試   | 21 |
| **Phase 4 小計** | | **46** |

### Integration Tests — Phase 1 + Phase 2 + Phase 3 端到端測試

| 測試檔案 | 說明 | 案例數 |
|----------|------|--------|
| `spec/integration/game_flow_spec.rb` | CLI 遊戲流程整合測試 | 16 |
| `spec/integration/api_flow_spec.rb`  | HTTP API 整合測試     | 3  |
| **Integration 小計** | | **19** |

### 全部合計

| | 案例數 |
|-|--------|
| Phase 1 單元測試 (RSpec) | 194 |
| Phase 2 單元測試 (RSpec) | 48 |
| Phase 3 單元測試 (RSpec) | 37 |
| Integration 測試 (RSpec) | 19 |
| Phase 4 前端測試 (Jest)  | 46 |
| **Ruby 合計** | **277** |
| **Frontend 合計** | **46** |

> Ruby 測試執行：`bundle exec rspec`
> Frontend 測試執行：`npm run test:frontend`

---

## 座標系說明

所有測試使用 `[rank, file]` 格式（0-indexed）：

| 陣列表示 | 代數記譜法 | 說明 |
|----------|-----------|------|
| `[0, 4]` | e1 | 白方 King 起始位置 |
| `[7, 4]` | e8 | 黑方 King 起始位置 |
| `[1, 4]` | e2 | 白方 e 兵起始位置 |
| `[6, 4]` | e7 | 黑方 e 兵起始位置 |

---

## Board（棋盤）測試

**測試檔案：** `spec/chess/board_spec.rb`

### `#piece_at`
- 空棋盤回傳 `nil`
- 放置棋子後能正確取回

### `#place`
- 將棋子寫入 grid
- 同時更新棋子的 `position` 屬性
- 放置 `nil` 等同清空格子

### `#remove`
- 移除並回傳棋子，格子變 `nil`
- 格子本已為空時回傳 `nil`

### `#move_piece`
- 棋子從 from 移動到 to
- 更新棋子的 `position` 屬性
- 將 `moved` flag 設為 `true`
- 目標格有棋子時直接覆蓋（吃子）

### `#empty?`
- 空格回傳 `true`
- 有棋子回傳 `false`

### `#pieces`
- 初始盤面共 32 枚棋子
- 白方 16 枚，黑方 16 枚

### `#king_position`
- 回傳指定顏色 King 的位置
- 沒有 King 時回傳 `nil`

### `#deep_clone`
- 回傳獨立副本，修改原盤不影響副本
- 修改副本不影響原盤
- 複製 `en_passant_target`
- 複製棋子的 `moved` flag

### `#setup_initial_position`
- 白方 King 在 e1 `[0,4]`，黑方 King 在 e8 `[7,4]`
- 白方 Queen 在 d1 `[0,3]`
- 白方 Rook 在 a1 `[0,0]` 和 h1 `[0,7]`
- 白方 8 枚 Pawn 在 rank 2，黑方 8 枚 Pawn 在 rank 7
- rank 3–6 全部為空
- 所有棋子 `moved?` 初始為 `false`

---

## Piece — King 測試

**測試檔案：** `spec/chess/pieces/king_spec.rb`

### 基本移動
- 從中央 `[4,4]` 可以到達所有 8 個相鄰格（驗證具體目標格列表）
- 角落位置（a1 `[0,0]`）只有 3 個合法目標格
- 不能移動到己方棋子所在格
- 可以捕獲敵方棋子
- 一般步驟的 `type` 為 `:normal`

### 王車易位（Castling）
- 王翼（Kingside）：路徑清空時生成 `[0,6]`，`type: :castle_kingside`
- 后翼（Queenside）：路徑清空時生成 `[0,2]`，`type: :castle_queenside`
- King 移動過後不生成易位移動
- 王翼 Rook 移動過後不生成王翼易位
- 后翼 Rook 移動過後不生成后翼易位
- f1 `[0,5]` 有棋子時不生成王翼易位
- g1 `[0,6]` 有棋子時不生成王翼易位
- b1 `[0,1]` 有棋子時不生成后翼易位

### 符號
- 白方 `♔`，黑方 `♚`

---

## Piece — Queen 測試

**測試檔案：** `spec/chess/pieces/queen_spec.rb`

### 滑行移動
- 沿橫向 rank 可到達所有格（7 個）
- 沿縱向 file 可到達所有格（7 個）
- 沿兩條對角線均可到達（驗證 `[0,0]`、`[7,7]`、`[0,6]`、`[6,0]`）

### 阻擋
- 己方棋子阻擋：停在其前一格，不能越過
- 敵方棋子阻擋：可以捕獲，不能繼續

### 角落位置
- 從 a1 `[0,0]` 出發使用新鮮棋盤（避免其他棋子干擾），確認可到達 `[0,7]`、`[7,0]`、`[7,7]`

### 符號
- 白方 `♕`，黑方 `♛`

---

## Piece — Rook 測試

**測試檔案：** `spec/chess/pieces/rook_spec.rb`

### 正交滑行
- 橫向覆蓋同 rank 所有 7 格
- 縱向覆蓋同 file 所有 7 格
- 不能斜向移動（驗證 `[4,4]`、`[2,2]` 不在結果中）
- 空棋盤中央精確產生 14 個移動

### 阻擋
- 己方棋子前一格停止，無法繼續
- 敵方棋子可以捕獲，且無法繼續

### 符號
- 白方 `♖`，黑方 `♜`

---

## Piece — Bishop 測試

**測試檔案：** `spec/chess/pieces/bishop_spec.rb`

### 斜向滑行
- 四個對角方向均可到達（驗證 `[0,0]`、`[7,7]`、`[0,6]`、`[6,0]`）
- 不能橫向或縱向移動
- 永遠停在同色格子（驗證所有目標格的 `(rank+file)%2` 恆等）

### 阻擋
- 己方棋子阻擋：停在其前一格
- 敵方棋子：可以捕獲，不能繼續

### 符號
- 白方 `♗`，黑方 `♝`

---

## Piece — Knight 測試

**測試檔案：** `spec/chess/pieces/knight_spec.rb`

### L 型移動
- 從 d4 `[3,3]` 精確產生 8 個目標格（列出全部 8 個位置）
- 角落 a1 `[0,0]` 只有 2 個目標格
- 邊緣 a4 `[3,0]` 有 4 個目標格

### 跳躍
- 四周被己方棋子包圍時仍然能移動（驗證跳過的能力）

### 捕獲
- 可以捕獲 L 格上的敵方棋子
- 不能移動到己方棋子所在的 L 格

### 符號
- 白方 `♘`，黑方 `♞`

---

## Piece — Pawn 測試

**測試檔案：** `spec/chess/pieces/pawn_spec.rb`

### 白方兵

#### 前進
- 前進一格（任意位置）
- 從起始 rank 1 前進兩格
- 中間格被阻擋時不能前進兩格
- 目標格被阻擋時不能前進兩格（但仍可前進一格）
- 正前方有棋子時不能前進
- 不能後退

#### 斜向捕獲
- 斜前方有敵方棋子時可以捕獲
- 正前方有敵方棋子時不能捕獲（非斜向）
- 斜前方為空時不能斜向移動
- 不能捕獲己方棋子

#### 過路兵（En Passant）
- 向左的 en passant（`en_passant_target` 在左前方）
- 向右的 en passant（`en_passant_target` 在右前方）
- `en_passant_target` 不相鄰時不生成此移動
- `en_passant_target` 為 `nil` 時不生成此移動
- 生成的 Move `type` 為 `:en_passant`

#### 升變（Promotion）
- 到達 rank 7 時生成 4 個升變移動（queen、rook、bishop、knight）
- 目標格 `type` 均為 `:promotion`，不包含 `:normal`
- 捕獲時到達 rank 7 也生成 4 個升變捕獲移動

### 黑方兵
- 向 rank 0 方向前進一格
- 從 rank 6 可以前進兩格
- 不能向 rank 8 方向移動（白方方向）
- 斜向捕獲朝 rank 0 方向
- 到達 rank 0 生成 4 個升變移動
- en passant 捕獲

### 符號
- 白方 `♙`，黑方 `♟`

---

## MoveValidator 測試

**測試檔案：** `spec/chess/move_validator_spec.rb`

### `#in_check?`
- 沒有 King 時回傳 `false`（不崩潰）
- King 安全時回傳 `false`
- 被 Rook 沿同 rank 攻擊 → `true`
- 被 Rook 沿同 file 攻擊 → `true`
- Rook 被己方棋子阻擋時 → `false`
- 被 Bishop 沿對角線攻擊 → `true`
- 被 Queen 沿對角線攻擊 → `true`
- 被 Knight L 型攻擊 → `true`
- 被 Pawn 斜前方攻擊 → `true`
- Pawn 正前方不算攻擊 → `false`
- 對黑方的 check 偵測同樣有效

### `#legal_moves` — check 過濾
- 移動後讓己方 King 暴露在攻擊下的移動被排除（釘子棋子測試）
- King 被將軍時可移動到安全格（驗證移動後不在 check 的格子）
- 被將軍時可以用己方棋子阻擋（插入格驗證）
- 被將軍時可以捕獲攻擊方棋子

### `#legal_moves` — 王車易位
- 路徑清空且安全時包含王翼易位
- 路徑清空且安全時包含后翼易位
- King 本身在 check 中時排除所有易位
- King 會經過受攻擊格時排除王翼易位（敵方 Rook 攻擊 f1）
- King 會經過受攻擊格時排除后翼易位（敵方 Rook 攻擊 d1）
- 目標格受到攻擊時排除易位（由 `safe_after_move?` 處理）

### `#apply_move!`
- 一般移動：棋子從 from 到 to
- 雙格前進後 `en_passant_target` 被設定為中間格
- 非雙格前進後 `en_passant_target` 清除為 `nil`
- En passant：移動捕獲方兵，並移除被捕獲的兵（不在目標格上）
- 王翼易位：King 到 g1 `[0,6]`，Rook 到 f1 `[0,5]`，原位清空
- 后翼易位：King 到 c1 `[0,2]`，Rook 到 d1 `[0,3]`，原位清空
- 升變：兵被指定棋子取代（顏色保持正確）
- `promotion_piece` 為 `nil` 時預設升變為 Queen

### `#checkmate?`
- 一般局面回傳 `false`
- 後排將死（King 在角落，Queen 和 King 包圍）→ `true`
- King 可以逃跑時回傳 `false`

### `#stalemate?`
- 有合法移動時回傳 `false`
- 在 check 中時回傳 `false`（那是將死，不是逼和）
- 經典角落逼和位置（白 King a1、黑 Queen b3、黑 King c2）→ `true`

---

## Game 測試

**測試檔案：** `spec/chess/game_spec.rb`

### 初始狀態
- `current_turn` 為 `:white`
- `status` 為 `:playing`
- `move_history` 為空陣列
- 棋盤有 32 枚棋子

### `#make_move` — 合法移動
- 回傳 `{ success: true }`
- 切換 `current_turn`
- 移動加入 `move_history`
- 棋盤狀態更新（棋子出現在目標格，from 清空）

### `#make_move` — 非法移動
- 回傳 `{ success: false, status: :illegal }`
- `current_turn` 不改變
- 移動不加入 `move_history`
- 拒絕移動對方棋子
- 拒絕移動後讓己方 King 暴露的移動

### 狀態偵測
- 被將軍後 `status` 變為 `:check`
- 將死後 `status` 變為 `:checkmate`，`over?` 為 `true`
- 逼和後 `status` 變為 `:stalemate`，`over?` 為 `true`

### `#legal_moves`
- 回傳非空的 `Chess::Move` 陣列
- 所有移動的 from 格子都屬於當前玩家

### `#in_check?`
- 開局狀態回傳 `false`

### `#current_state`
- 包含 `:board`、`:turn`、`:status`、`:en_passant_target` 四個鍵
- `turn` 反映當前玩家
- `board` Hash 共 64 個鍵（a1–h8）

### 兵的升變
- 以 `type: :promotion, promotion_piece: :queen` 的 Move 可以成功執行
- 執行後目標格棋子為 `Chess::Pieces::Queen`

---

## Serializer 測試

**測試檔案：** `spec/chess/serializer_spec.rb`

### `.save`
- 在指定路徑建立檔案
- 檔案內容為合法 YAML（以 `---` 開頭）

### `.load` — 還原驗證
- `current_turn` 正確還原（如移動一步後為 `:black`）
- 棋子位置正確還原（from 格清空，to 格有棋子）
- `move_history` 長度與內容（from/to）正確
- 棋子 `moved?` flag 正確還原（移動過的兵為 `true`）
- `en_passant_target` 正確還原（雙格前進後為中間格）
- 易位權限（`moved?` 為 `false` 的 King）正確還原
- `status` 正確還原為 `:playing`

### 完整 Round-Trip
- 多步移動後存/讀，所有棋子位置全部吻合
- `move_history` 長度正確
- 升變後的 Queen 存/讀後仍為 Queen

---

## 測試場景備忘

### 後排將死（Back-rank Checkmate）
```
位置：白 King h1 [0,7]、黑 Queen g2 [1,6]、黑 King f3 [2,5]
- 白 King 在 check（黑 Queen 斜線攻擊 h1）
- g1 [0,6]：黑 Queen 攻擊（正交）
- g2 [1,6]：黑 Queen 在此，King 若吃則被黑 King 攻擊
- h2 [1,7]：黑 Queen 攻擊（正交）
→ White checkmate
```

### 經典逼和（Corner Stalemate）
```
位置：白 King a1 [0,0]、黑 Queen b3 [2,1]、黑 King c2 [1,2]
- 白 King 不在 check
- a2 [1,0]：黑 Queen 對角線攻擊；b1 [0,1]：黑 Queen 縱向攻擊，黑 King 鄰接攻擊；
  b2 [1,1]：黑 King 鄰接攻擊，黑 Queen 縱向攻擊
→ White stalemate
```

### 過路兵（En Passant）測試情境
```
白方兵 d5 [4,3]、黑方兵剛從 e7 [6,4] → e5 [4,4] 雙步前進
en_passant_target = [5,4]（e6）
白方兵可以移動到 [5,4]，同時移除 [4,4] 的黑方兵
```

### 王車易位被阻情境
```
白 King [0,4]、白 Rook [0,7]
敵方 Rook 在 [7,5]（攻擊 f1 [0,5]，即王翼易位的必經格）
→ 王翼易位被排除
```

---

## Phase 2 — CLI Adapter 測試

### Renderer（`spec/chess/cli/renderer_spec.rb`）

#### 輸出結構
- 頂行和底行包含欄標 a–h
- 輸出包含列標 1–8
- 共 10 行（標頭 + 8 rank + 頁尾）

#### 棋子渲染
- 初始盤面包含所有 Unicode 棋子符號（♔ ♕ ♖ ♗ ♘ ♙ ♚ ♛ ♜ ♝ ♞ ♟）

#### last_move 高亮
- `last_move: nil` 不崩潰
- 傳入 last_move 時，輸出包含 `HIGHLIGHT_BG` ANSI 碼
- 無 last_move 時不出現高亮碼

#### check 高亮
- `in_check_color` 指定方的 King 位置套用 `CHECK_BG` ANSI 碼
- `in_check_color: nil` 時不出現 check 背景

#### ANSI 重置
- 輸出包含 `RESET` 碼，防止顏色溢出

---

### InputParser（`spec/chess/cli/input_parser_spec.rb`）

#### 指令
- `"save"` → `{ type: :save }`
- `"resign"` → `{ type: :resign }`
- `"quit"` / `"exit"` → `{ type: :quit }`
- 大小寫不敏感（`"SAVE"`、`"Quit"` 均可）
- 前後空白被 strip

#### 移動解析 — 間隔格式
- `"e2 e4"` → `from: [1,4], to: [3,4]`
- `"a1 h8"` 和 `"h8 a1"` 角落對角
- 無升變後綴時 `promotion_piece: nil`

#### 移動解析 — 緊湊格式
- `"e2e4"` → 正確解析 from / to

#### 升變移動
- `"e7 e8q"` → `promotion_piece: :queen`
- `"e7 e8r"` / `"e7 e8b"` / `"e7 e8n"` → 對應棋子符號
- 緊湊格式 `"e7e8q"` 亦可
- 未知後綴（如 `"e7 e8x"`）→ `{ type: :error }`

#### 無效輸入
- 亂碼、超出範圍格子、單一格子、空字串 → `{ type: :error }`

---

### Runner（`spec/chess/cli/runner_spec.rb`）

#### 啟動
- 顯示 `CHESS` 標題
- 無存檔時不詢問讀取

#### 移動流程
- 渲染棋盤（包含 Unicode 棋子）
- 無效輸入顯示錯誤訊息
- 非法移動顯示 `Illegal move` 提示
- 合法移動後顯示 Black's turn

#### 存檔
- `"save"` 指令建立 `.yml` 檔案
- 顯示 `Saved` 確認訊息

#### 投降
- `"resign"` 顯示 `Black wins`

#### 刪除存檔（啟動選單）
- 輸入 `d1` 時對應的 `.yml` 檔案從磁碟刪除
- 顯示 `Deleted: <filename>` 確認訊息
- 刪除後清單為空時自動開始新遊戲（不再提示選單）
- `d99`（超出範圍索引）顯示 `Invalid choice` 並重新提示，原檔案不受影響

---

## Phase 3 — Web API 測試

### GameStore（`spec/app/game_store_spec.rb`）

#### `#create`
- 回傳 UUID 格式字串
- 初始化新的 `Chess::Game`
- `size` 遞增

#### `#get`
- 以已知 id 回傳 Game
- 未知 id 回傳 `nil`
- 更新 last-accessed 時間戳記

#### `#load`
- 注入已有 Game，回傳新 UUID
- 回傳的 id 可正常讀取該 Game

#### `#delete`
- 從 store 移除 Game
- `size` 遞減

#### `#size`
- 回傳目前儲存的 Game 數量

#### TTL 淘汰
- 超過 TTL 的 Game 在下次 `get` 時被移除
- 近期存取的 Game 不受影響

---

### API（`spec/app/api_spec.rb`）

#### `POST /games`
- 回傳 201
- 回應包含 `game_id`
- `state` 包含 `board`、`turn`、`status`、`legal_moves`

#### `GET /games/saved`
- 回傳 200 與 `saves` 陣列
- 列出目錄中現有的 `.yml` 檔案

#### `GET /games/:id`
- 有效 id 回傳 200 與 `state`
- 未知 id 回傳 404

#### `POST /games/:id/moves`
- 合法移動回傳 200，`state.turn` 切換
- 非法移動回傳 422
- 缺少 `from`/`to` 回傳 400
- 格子格式錯誤（如 `z9`）回傳 400
- 未知 game id 回傳 404
- 升變但未附 `promotion` 欄位 → 422，錯誤訊息說明需指定棋子
- 升變附 `promotion: "queen"` → 200，`board` 中目標格為 Queen

#### `POST /games/:id/save`
- 在 `saves_dir` 產生 `.yml` 檔案
- 回應包含 `saved` 檔名

#### `POST /games/load/:save_name`
- 回傳 201，包含 `game_id` 與 `state`
- 未知 save_name 回傳 404
- 讀取後棋盤狀態與存檔一致

#### `DELETE /games/saved/:save_name`
- 回傳 200，檔案從磁碟刪除
- 未知 save_name 回傳 404

#### `DELETE /games/:id`
- 回傳 200，回應包含投降訊息
- 刪除後 `GET /games/:id` 回傳 404
- 未知 id 回傳 404

---

## Integration Tests — Phase 1 + Phase 2 + Phase 3

### CLI 整合（`spec/integration/game_flow_spec.rb`）

**測試檔案：** `spec/integration/game_flow_spec.rb`

### 開局移動
- 白 e2→e4、黑 e7→e5 均成功
- 棋盤反映移動後的棋子位置
- `move_history` 正確累積

### Scholar's Mate（4步將死）
- 完整 7 步後 `status: :checkmate`，`over?: true`

### Check 狀態渲染
- 被將軍時，Renderer 在 King 格套用 `CHECK_BG`

### 逼和（Stalemate）
- 角落逼和局面 `status: :stalemate`

### 過路兵 — 端到端
- 輸入 `"d5 e6"` → 解析為 `:en_passant` 移動 → 執行後被吃兵消失、捕獲方兵到達目標格

### 兵的升變 — 端到端
- 輸入 `"e7 e8q"` → 解析 `promotion_piece: :queen` → 執行後目標格為 `Chess::Pieces::Queen`

### 王車易位 — 端到端
- 輸入 `"e1 g1"` → 找到 `:castle_kingside` 合法移動 → King 到 g1、Rook 到 f1

### 存檔/讀檔/刪除 — 端到端
- 兩步後 `Serializer.save` + `Serializer.load` → turn、history、棋子位置全部吻合
- Runner 執行 `save` 指令後在目錄產生 `.yml` 檔案
- Runner 啟動選單輸入 `d1` → 存檔從磁碟刪除、顯示 `Deleted`、自動進入新遊戲

### 非法移動防止
- `legal_moves` 不包含對方棋子的移動
- 直接對 `make_move` 提交對方棋子移動 → `success: false`
- 被釘住的 Rook 側向移動 → `success: false`

### Renderer 反映引擎狀態
- 吃子後的 last_move 高亮出現在輸出中

---

### API 整合（`spec/integration/api_flow_spec.rb`）

#### Scholar's Mate via HTTP
- `POST /games` → 連續 7 次 `POST /games/:id/moves` → 最後回應 `state.status: "checkmate"`

#### Save → Load Round-Trip
- 建立遊戲、走兩步 → `POST /games/:id/save` → `POST /games/load/:save_name`
- 讀取後棋子位置（e4、e5）與輪次（white）完全一致

#### Resign via DELETE
- `POST /games` → `DELETE /games/:id` → 訊息包含 "White resigns" 和 "Black wins"
- 刪除後 `GET /games/:id` 回傳 404

---

## Phase 4 — Frontend 測試（Jest + jsdom）

測試框架：**Jest 29**，環境：**jsdom**（模擬瀏覽器 DOM）
執行指令：`npm run test:frontend`

---

### Api（`spec/frontend/api.test.js`）

#### `createGame`
- 向 `POST /games` 發送請求
- 回傳回應資料（含 `game_id`）

#### `makeMove`
- 向 `POST /games/:id/moves` 發送 from/to body
- 有 promotion 時加入 `promotion` 欄位
- 無 promotion 時省略 `promotion` 欄位

#### `resign`
- 向 `DELETE /games/:id` 發送請求

#### `saveGame`
- 向 `POST /games/:id/save` 發送請求

#### `listSaves`
- 向 `GET /games/saved` 發送請求

#### `loadSave`
- 向 `POST /games/load/:name` 發送請求

#### `deleteSave`
- 向 `DELETE /games/saved/:name` 發送請求

#### 錯誤處理
- 非 2xx 回應時拋出帶有 `status` 屬性的錯誤

---

### Board / render（`spec/frontend/board.test.js`）

#### 棋盤結構
- 建立精確 64 個 `.square` 元素
- 32 個 light 格、32 個 dark 格
- a1 為 dark（標準西洋棋底色）
- b1 為 light
- h8 為 dark

#### 棋子渲染
- 白方兵渲染為 `♙`
- 黑方 King 渲染為 `♚`
- 白方 Queen 渲染為 `♕`
- 空格不產生 `.piece` 元素

#### 選取與合法目標
- 被選取的格子加上 `selected` class
- 非選取格不加 `selected`
- 合法目標格加上 `legal-target` class
- 非目標格不加 `legal-target`

#### Last-move 高亮
- from 與 to 格加上 `last-move` class
- `last_move: null` 時不產生任何 `last-move`

#### Check 高亮
- `status: 'check'` 時，當前玩家的 King 格加上 `in-check` class
- `status: 'playing'` 時不加 `in-check`
- 對手方 King 不加 `in-check`

---

### App 狀態機（`spec/frontend/app.test.js`）

#### `start()`
- 呼叫 `api.createGame()` 一次
- 建立 64 個格子並渲染棋盤
- 儲存 `gameId` 與初始 `state`
- 重置 `moveHistory`
- 隱藏 game-over modal
- 更新 status bar 文字

#### 棋子選取（`handleSquareClick`）
- 點擊己方棋子 → 選取，`uiState: 'piece_selected'`，顯示 `legal-target`
- 閒置時點擊空格 → 無動作
- 選取後點擊非目標格 → 取消選取，回到 `idle`
- 選取後點擊另一己方棋子 → 改選新棋子

#### 移動提交
- 點擊合法目標格 → 呼叫 `api.makeMove(gameId, from, to, null)`
- 移動後重置選取，`uiState` 回到 `idle`
- 移動加入 `moveHistory`（格式 `from→to`）
- 遊戲結束後點擊不觸發移動

#### 兵的升變
- 白方兵到達 rank 8（或黑方到 rank 1）→ 顯示 promotion modal，`uiState: 'awaiting_promotion'`
- 選擇升變棋子後呼叫 `api.makeMove(gameId, from, to, piece)`，隱藏 modal

#### 遊戲結束
- `status: 'checkmate'` → 顯示 game-over modal，文字為結局訊息
- `status: 'stalemate'` → 顯示 game-over modal
