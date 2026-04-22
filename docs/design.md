# Chess — 系統設計文件

## 核心設計原則

**關鍵決策：將棋局邏輯與 I/O 層完全分離。**

Chess engine（核心邏輯）不知道自己是在 CLI 還是網頁上執行。
CLI adapter 和 Web API adapter 都只是棋局引擎的「使用者」。

```
┌─────────────────────────────────────────────────────┐
│                   Chess Engine (lib/)               │
│        Board, Pieces, MoveValidator, Game           │
└────────────────────┬────────────────────────────────┘
                     │
          ┌──────────┴──────────┐
          │                     │
   ┌──────▼──────┐       ┌──────▼──────┐
   │  CLI Runner │       │   Web API   │
   │  (bin/chess)│       │  (Sinatra)  │
   └─────────────┘       └──────┬──────┘
                                │  JSON / WebSocket
                         ┌──────▼──────┐
                         │  Frontend   │
                         │  (HTML/JS)  │
                         └─────────────┘
```

---

## 後端設計

### 目錄結構

```
odin_chess/
├── lib/
│   └── chess/
│       ├── pieces/
│       │   ├── piece.rb          # 抽象父類別
│       │   ├── king.rb
│       │   ├── queen.rb
│       │   ├── rook.rb
│       │   ├── bishop.rb
│       │   ├── knight.rb
│       │   └── pawn.rb
│       ├── board.rb              # 棋盤狀態管理
│       ├── game.rb               # 回合流程、勝負判斷
│       ├── move_validator.rb     # 合法移動過濾（含 check 偵測）
│       ├── move.rb               # Move value object
│       └── serializer.rb        # 存檔/讀檔
├── bin/
│   └── chess                    # CLI 入口點
├── app/
│   ├── api.rb                   # Sinatra Web API
│   └── game_store.rb            # 記憶體/檔案 session 管理
├── frontend/
│   ├── index.html
│   ├── css/
│   │   └── board.css
│   └── js/
│       ├── board.js             # 棋盤渲染
│       ├── api.js               # 與後端溝通
│       └── app.js               # 主控邏輯
├── spec/                        # RSpec 測試
└── saves/                       # 存檔目錄
```

---

### Chess Engine 層（lib/chess/）

#### `Piece`（父類別）

```
屬性：color (:white | :black), position ([rank, file])
方法：
  - moves(board)              → Array<Move>  # 原始移動（不考慮 check）
  - symbol                    → String       # Unicode 符號
  - moved?                    → Boolean      # 是否移動過（用於 castling）
```

每個子類別只負責自身的移動向量，不處理 check 過濾。

#### `Board`

```
職責：管理 8×8 格子狀態，不做規則判斷
屬性：
  - grid[8][8]                # 格子，nil 或 Piece
  - en_passant_target         # [rank, file] | nil
方法：
  - piece_at(pos)             → Piece | nil
  - place(piece, pos)
  - move_piece(from, to)      → captured_piece | nil
  - deep_clone                → Board  # 用於 check 偵測的模擬
  - to_fen                    → String # 可選：FEN 輸出
  - to_h                      → Hash   # 序列化用
```

#### `Move`（Value Object）

```
屬性：
  - from, to                  # [rank, file]
  - type                      # :normal | :castle_kingside | :castle_queenside
                              #         | :en_passant | :promotion
  - promotion_piece           # :queen | :rook | :bishop | :knight（promotion 時）
```

#### `MoveValidator`

```
職責：過濾合法移動，偵測 check / checkmate / stalemate
方法：
  - legal_moves(color, board, history)     → Array<Move>
  - in_check?(color, board)                → Boolean
  - checkmate?(color, board, history)      → Boolean
  - stalemate?(color, board, history)      → Boolean

內部邏輯：
  legal_moves = raw_moves 過濾掉「執行後己方 King 仍在 check」的移動
  每次過濾都使用 board.deep_clone 模擬，不修改真實棋盤
```

#### `Game`

```
職責：回合流程、狀態機、勝負判斷
狀態機：
  :waiting_input → :validating → :executing → :checking_result → :waiting_input
                                                               ↓
                                                    :check / :checkmate / :stalemate

方法：
  - start                      # 初始化棋盤、進入回合迴圈
  - make_move(move)  → Result  # Result: { status, board_state, message }
  - current_state    → Hash    # 供 API 序列化整個遊戲狀態
  - save(path)
  - self.load(path)  → Game
```

`Game#make_move` 是引擎的唯一公開入口：CLI 和 Web API 都只呼叫這個方法。

#### `Serializer`

使用 YAML 序列化 `Game#current_state`（純 Hash，不序列化物件實體），
讀檔時從 Hash 重建物件。避免 Marshal 的版本耦合問題。

---

### CLI Adapter（bin/chess）

```
流程：
  1. 詢問新遊戲或讀取存檔（ask_new_or_load 迴圈）
     - 顯示存檔清單（編號 1, 2, …）
     - 輸入數字 → 讀取對應存檔
     - 輸入 n → 新遊戲
     - 輸入 d<n>（例如 d1）→ 刪除該存檔，重新顯示清單
       * 若刪除後清單為空 → 直接開始新遊戲
       * 索引超出範圍 → 顯示 "Invalid choice." 重新提示
  2. 進入迴圈：
     a. 渲染棋盤（ANSI 色彩 + Unicode 棋子）
     b. 顯示狀態訊息（check / 輪到哪方）
     c. 讀取輸入（e2 e4 / save / resign）
     d. 解析輸入 → Move
     e. game.make_move(move) → 顯示結果或錯誤
  3. 遊戲結束時顯示勝負

CLI 只負責 I/O，不含任何棋規邏輯。
```

#### 存檔選單輸入一覽

| 輸入 | 動作 |
|------|------|
| `1`–`n` | 讀取第 n 個存檔 |
| `n`（或直接 Enter） | 開始新遊戲 |
| `d1`–`d<n>` | 刪除第 n 個存檔，重新顯示清單 |

---

### Web API（app/api.rb — Sinatra）

#### Session 管理

```
GameStore：
  - 以 game_id（UUID）為 key，存放 Game 實體於記憶體
  - 超過閒置時間（30 分鐘）自動清除
  - 可選：持久化到 saves/ 目錄
```

#### REST Endpoints

```
POST   /games                    # 建立新遊戲
                                 # Response: { game_id, state }

GET    /games/:id                # 取得當前棋盤狀態
                                 # Response: { state }

POST   /games/:id/moves          # 執行移動
                                 # Body: { from: "e2", to: "e4" }
                                 #       { from: "e1", to: "g1", type: "castle_kingside" }
                                 #       { from: "e7", to: "e8", promotion: "queen" }
                                 # Response: { status, state, message }

POST   /games/:id/save           # 儲存遊戲到檔案
GET    /games/saved              # 列出存檔
POST   /games/load/:save_name    # 從存檔恢復遊戲

DELETE /games/:id                # 結束遊戲（投降）
```

#### `state` 回應格式

```json
{
  "board": {
    "e2": { "type": "pawn", "color": "white" },
    "e4": null,
    ...（64 個格子）
  },
  "turn": "white",
  "status": "check",
  "legal_moves": {
    "e1": ["d1", "f1"],
    ...（當前玩家所有合法移動）
  },
  "last_move": { "from": "e2", "to": "e4" },
  "message": "White is in check!"
}
```

前端收到 `legal_moves` 後即可在 UI 上標示可移動格子，不需要再向後端詢問。

---

## 前端設計

### 技術選擇

**Vanilla JS + HTML/CSS**（不使用框架）

理由：題目本身是棋局邏輯練習，前端保持簡單；也方便之後替換成任何框架。

### 頁面結構

```
┌──────────────────────────────────────────────────┐
│  Chess                              [Save] [Quit] │
├───────────────────┬──────────────────────────────┤
│                   │  Status Bar                  │
│   Chess Board     │  "White's turn"              │
│   (8×8 grid)      │  "Black is in check!"        │
│                   ├──────────────────────────────┤
│                   │  Move History                │
│                   │  1. e2→e4  e7→e5             │
│                   │  2. d2→d4  ...               │
│                   │                              │
└───────────────────┴──────────────────────────────┘
```

### 棋盤互動流程（js/app.js）

```
狀態機：
  idle → piece_selected → awaiting_promotion → idle
         ↑（點錯格子）↙（點擊合法目標格）

1. 點擊己方棋子：
   - 標記為 selected
   - 用 legal_moves（來自 state）在畫面上標示可移動格子

2. 點擊高亮格子：
   - 若為 promotion 升變：顯示選擇 UI（Queen/Rook/Bishop/Knight）
   - 否則直接呼叫 POST /games/:id/moves

3. 收到回應：
   - 更新整個 board（用新的 state 重新渲染）
   - 若 status === "checkmate" 或 "stalemate"：顯示遊戲結束 modal

4. 點擊非法格子：取消選取，回到 idle
```

### 模組拆分

```
js/
├── api.js      # 封裝所有 fetch 呼叫，統一錯誤處理
├── board.js    # 純渲染：state → DOM，不含狀態
└── app.js      # 狀態機、事件處理、串聯 api.js 和 board.js
```

`board.js` 是純函式：`render(state, selectedPos, legalTargets)` → 更新 DOM。
所有狀態都在 `app.js` 持有，`board.js` 不持有任何狀態。

### 棋盤渲染細節（board.js）

```
- 64 個 <div class="square"> 組成棋盤
- 格子顏色：light / dark（由 CSS 控制）
- 棋子：Unicode 字元放在格子內
- selected：高亮已選棋子
- legal-target：標示可移動格子（淡綠色圓點）
- last-move：標示上一步的 from / to（淡黃色背景）
- in-check：King 格子紅色邊框
```

---

## 開發順序建議

```
Phase 1 — Chess Engine（純邏輯，無 I/O）
  ├── Board + Piece 資料結構
  ├── 各棋子移動邏輯
  ├── MoveValidator（check 偵測、合法移動過濾）
  ├── 特殊移動（En Passant, Castling, Promotion）
  ├── Checkmate / Stalemate 偵測
  └── RSpec 測試（伴隨每個功能撰寫）

Phase 2 — CLI Runner
  ├── 棋盤渲染（ANSI + Unicode）
  ├── 輸入解析
  └── 存檔 / 讀檔

Phase 3 — Web API
  ├── Sinatra 架設
  ├── GameStore session 管理
  └── REST endpoints

Phase 4 — Frontend
  ├── 棋盤 HTML/CSS
  ├── board.js 渲染
  ├── api.js
  └── app.js 狀態機 + 互動
```

Phase 1 完全不依賴任何 I/O，可以 100% 靠 RSpec 驗證正確性後，再接上 CLI 和 Web。
