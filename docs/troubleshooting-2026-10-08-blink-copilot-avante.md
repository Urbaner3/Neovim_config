# 2026-10-08 補完與 AI 問答重現記錄

本檔整理當天問答上下文：每個問題的現象、重現步驟、根因、修正與驗證。
相關路徑（repo 根目錄 = `~/.config/nvim`）：

- `lua/plugins/ai.lua`（blink.cmp / copilot.vim / avante 規格）
- `lazy-lock.json`（`avante.nvim` → `4f49656`，新增 `mega.cmdparse` / `mega.logging`）
- 上游唯讀參考：`~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/extras/coding/blink.lua`
- 上游 preset 定義：`~/.local/share/nvim/lazy/blink.cmp/lua/blink/cmp/keymap/presets.lua`

## Q1：LazyVim 自動完成按鍵是哪個？

- 現象：不知道按什麼接受補完。
- 確認：`extras/coding/blink.lua:102-105` 用 `preset = "enter"`，外加
  `["<C-y>"] = { "select_and_accept" }`。展開 preset（`presets.lua:73-90`）：
  `<CR>` = `accept`，`<C-y>` = 選首項再接受；`<Tab>` 只走
  `snippet_forward / ai_nes / ai_accept`，不是選單接受鍵。

## Q2：C-Space 跟 Ubuntu 撞鍵，且 CR / C-y 按了沒反應？

- 現象：`C-Space` 被系統輸入法吃掉；`Ref.cpp` 出現暗灰字，按 `CR` 只換行、灰字還在。
- 釐清：灰字是 `copilot.vim` 內聯建議，不是 blink 彈出選單。
  `CR/C-y` 只接受選單，所以換行是預期行為。且當時
  `LazyVim.cmp.actions` 只有 `snippet_forward/snippet_stop`，
  沒有 `ai_accept`，`Tab` 也吃不到 copilot.vim（LazyVim 只幫 `copilot.lua` 註冊）。
- 修正（`lua/plugins/ai.lua`）：
  - blink `keymap` 補 `<C-;>`、`<M-Space>` 做 `show` 替代鍵（保留 `C-Space`）。
  - `sources.default` 只留 `{ "avante" }`，其餘沿用 blink extra 預設（之前寫全會重複）。
  - 在 `copilot.vim` 的 `config` 註冊 `ai_accept`，`Tab` 可接受灰字，`M-l` 保留。
- 驗證（headless）：`actions` 含 `ai_accept`；
  `keymap` = `enter + C-y + C-; + M-Space`；
  `sources.default` = `{ lsp, path, snippets, buffer, avante }` 無重複；空啟動 `exit:0`。

## Q3：Tab 出現 `%80` 亂碼？

- 現象：`M-l` 正常，`Tab` 插入 `...%80...正確文字...%80`。
- 根因：`ai_accept` 里對 `copilot#Accept()` 回傳值又包了一層
  `nvim_replace_termcodes`，已是二進位的 `K_SPECIAL` 被二次轉義成字面文字。
- 修正：直接 `nvim_feedkeys(vim.fn["copilot#Accept"](), "i", true)`，
  另補 `LazyVim.create_undo()` 與 `copilot.lua` 版對齊。
- 驗證：空啟動無報錯，`ai_accept` 仍註冊；實機在 `Ref.cpp` 灰字處按 `Tab` 應與 `M-l` 一致。

## Q4：`Failed to source .../avante.nvim/plugin/avante.lua`？

- 現象：`msg_show` 報 avante plugin 載入失敗（與 Q2/Q3 修改無關，同次重啟浮現）。
- 根因：`avante.nvim@4f49656` 新增必備依賴 `mega.cmdparse`（`plugin/avante.lua:142`
  `require("mega.cmdparse")`，見 README 與 `init.lua` 註解），本 repo 的 avante
  `dependencies` 沒宣告，且環境無 luarocks/lazy-rocks，故 `dofile` 報
  `module 'mega.cmdparse' not found`。
- 修正：在 avante `dependencies` 加
  `{ "ColinKennedy/mega.cmdparse", dependencies = { "ColinKennedy/mega.logging" } }`，
  跑 `:Lazy sync` 裝好後 `dofile plugin/avante.lua` 回 `true`。
- 驗證：`lazy-lock.json` 新增 `mega.cmdparse` / `mega.logging`；空啟動 `exit:0`。
