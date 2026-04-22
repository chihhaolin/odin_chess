# Project: Chess — 專案目標與規格說明

## 專案目標

用 Ruby 打造一個可在命令列（CLI）執行的雙人西洋棋遊戲。
這是 The Odin Project Ruby 課程的最終壓軸專題，目標是整合你所學過的所有知識：
物件導向設計、序列化、測試，以及處理複雜邏輯的能力。

---

## 核心功能需求（Functional Requirements）

### 1. 遊戲基本流程

- 兩位玩家（白方 White / 黑方 Black）在同一台電腦輪流操作
- 白方先走，之後交替進行
- 每回合顯示當前棋盤狀態
- 玩家用輸入指令選擇棋子和目標格（建議支援代數記譜法，例如 `e2 e4`）
- 每回合結束後切換玩家

### 2. 棋盤（Board）

- 8×8 方格棋盤
- 縱向為 Rank（1–8），橫向為 File（a–h）
- 棋盤需在終端機中清楚顯示（可使用 Unicode 棋子符號增加視覺效果）
- 白方棋子放在 Rank 1–2，黑方棋子放在 Rank 7–8

### 3. 棋子初始配置

每方各 16 枚棋子：

| 棋子 | 數量 | Unicode（白/黑） |
|------|------|-----------------|
| King（王） | 1 | ♔ / ♚ |
| Queen（后） | 1 | ♕ / ♛ |
| Rook（城堡） | 2 | ♖ / ♜ |
| Bishop（主教） | 2 | ♗ / ♝ |
| Knight（騎士） | 2 | ♘ / ♞ |
| Pawn（兵） | 8 | ♙ / ♟ |

### 4. 棋子移動規則

#### King（王）
- 每次移動一格，可朝八個方向移動
- 不可移動到被對方棋子攻擊的格子

#### Queen（后）
- 可沿橫、縱、斜任意方向移動任意格數
- 路徑上不可有其他棋子阻擋

#### Rook（城堡）
- 可沿橫向或縱向移動任意格數
- 路徑上不可有其他棋子阻擋

#### Bishop（主教）
- 只能沿斜角方向移動任意格數
- 路徑上不可有其他棋子阻擋
- 整場遊戲永遠停留在同色格子

#### Knight（騎士）
- 走「L」形：先走兩格再走一格，或先走一格再走兩格（可跳過其他棋子）
- 共有最多 8 個可能目標格

#### Pawn（兵）
- 一般移動：每次向前一格（不可後退）
- 初始移動：從起始位置可選擇走兩格
- 捕獲：只能斜前方一格捕獲對方棋子（不可直走捕獲）

### 5. 特殊移動規則

#### 王車易位（Castling）
- King 和 Rook 均未移動過
- King 和 Rook 之間沒有任何棋子
- King 目前不在將軍（check）狀態
- King 移動路徑上的格子沒有被對方攻擊
- 執行：King 向 Rook 方向移動兩格，Rook 跳到 King 越過的格子
- 分為：王翼易位（Kingside, O-O）和后翼易位（Queenside, O-O-O）

#### 過路兵（En Passant）
- 當對方的 Pawn 從起始位置一次走兩格，落在己方 Pawn 旁邊時
- 己方 Pawn 可在**下一回合**立即捕獲該 Pawn（移動到其越過的格子）
- 若不在下一回合執行，此機會即消失

#### 兵的升變（Pawn Promotion）
- Pawn 抵達對方底線（白方到達第 8 Rank，黑方到達第 1 Rank）
- 立即升變為 Queen、Rook、Bishop 或 Knight（玩家選擇）
- 通常升為 Queen（稱為 underpromotion 若選其他棋子）

### 6. 將軍與將死

#### 將軍（Check）
- 當 King 正受到對方棋子攻擊時，進入 check 狀態
- 需向玩家顯示 "Check!" 提示
- 玩家**必須**在這一回合解除將軍，合法方式有三種：
  1. 移動 King 到安全格子
  2. 用己方棋子捕獲攻擊中的對方棋子
  3. 用己方棋子阻擋攻擊路線（僅限 Queen、Rook、Bishop 的攻擊）

#### 將死（Checkmate）
- King 在將軍中，且無任何合法移動可解除
- 遊戲結束，對方獲勝

#### 逼和（Stalemate）
- 輪到移動的玩家沒有任何合法移動，但 King **不在**將軍中
- 遊戲以平局結束

### 7. 非法移動防止

- 禁止玩家進行任何非法移動，需提示錯誤並要求重新輸入
- 禁止玩家移動後讓自己的 King 處於被將軍狀態
- 禁止移動對方棋子

### 8. 平局條件（Draw Conditions）

- **逼和（Stalemate）**：玩家沒有合法移動且不在將軍中
- **三重複局（Threefold Repetition）**：相同盤面出現三次（可選實作）
- **五十步規則（Fifty-Move Rule）**：連續 50 回合沒有 Pawn 移動或棋子被吃（可選實作）
- **協議和棋**：玩家雙方同意和棋（可選實作）

### 9. 存檔與讀檔（Save / Load）

- 玩家可在任意回合輸入指令儲存目前遊戲狀態
- 下次啟動時可選擇讀取已儲存的遊戲繼續進行
- 建議使用 Ruby 的 `Marshal` 或 `YAML` 進行序列化（serialization）
- 存檔需包含：棋盤狀態、目前輪到哪方、移動歷史（用於 En Passant、Castling 判斷）

---

## 程式設計規格（Technical Requirements）

### 物件導向設計

建議至少包含以下 Classes：

| Class | 職責 |
|-------|------|
| `Game` | 控制遊戲主流程、回合切換、勝負判斷 |
| `Board` | 管理棋盤格狀態、棋子位置 |
| `Player` | 代表玩家，處理輸入 |
| `Piece`（父類別） | 棋子共用屬性（顏色、位置）與介面 |
| `King` | King 的移動邏輯、易位判斷 |
| `Queen` | Queen 的移動邏輯 |
| `Rook` | Rook 的移動邏輯、易位判斷 |
| `Bishop` | Bishop 的移動邏輯 |
| `Knight` | Knight 的移動邏輯 |
| `Pawn` | Pawn 的移動、En Passant、升變邏輯 |

### 設計原則

- 每個方法只做一件事（Single Responsibility）
- 類別保持模組化，低耦合
- 避免在單一方法中塞入過多邏輯

### 輸入格式（建議）

使用代數記譜法（Algebraic Notation）：
```
> e2 e4       # 移動棋子從 e2 到 e4
> save        # 存檔
> resign      # 投降
```

---

## 測試需求（Testing Requirements）

使用 **RSpec** 撰寫單元測試，優先涵蓋：

- 各棋子的合法移動生成
- 將軍（Check）偵測邏輯
- 將死（Checkmate）偵測邏輯
- 逼和（Stalemate）偵測邏輯
- 特殊移動：En Passant、Castling、Pawn Promotion
- 非法移動的阻擋
- 存檔與讀檔功能

> 不一定要使用 TDD，但對任何你反覆手動在 console 測試的功能，都應寫成 RSpec 測試。

---

## 額外加分功能（Extra Credit）

- **簡易 AI 對手**：電腦玩家每回合從所有合法移動中隨機選一個執行
- **FEN 支援**：支援以 Forsyth-Edwards Notation 匯入/匯出棋盤狀態（方便使用 Lichess 等工具測試）
- **計時功能**：加入回合計時或整場計時

---

## 推薦開發順序

1. 建立棋盤和棋子的基本資料結構
2. 實作各棋子的基本移動邏輯
3. 實作路徑阻擋判斷
4. 實作 Check 偵測
5. 實作合法移動過濾（移動後不可讓己方 King 被將軍）
6. 實作 Checkmate 和 Stalemate 偵測
7. 實作 En Passant
8. 實作 Castling
9. 實作 Pawn Promotion
10. 實作存檔/讀檔
11. 撰寫 RSpec 測試
12. （選）實作 AI 對手

---

## 參考資源

- [The Odin Project - Project: Chess](https://www.theodinproject.com/lessons/ruby-chess)
- [Rules of Chess - Wikipedia](http://en.wikipedia.org/wiki/Chess)
- [Chess Notation - Wikipedia](https://en.wikipedia.org/wiki/Chess_notation)
- [Forsyth-Edwards Notation (FEN)](https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation)
- [Lichess Board Editor](https://lichess.org/editor)（棋盤視覺化測試工具）
- [Chess Symbols in Unicode](http://en.wikipedia.org/wiki/Chess_symbols_in_Unicode)