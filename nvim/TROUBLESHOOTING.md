# 🛠️ 故障排除指南

## 已修復的問題 (2025-01-04)

### ❌ 問題 1: timer_stop 錯誤
**錯誤訊息:**
```
E5101: Cannot convert given Lua type
E5108: Error executing lua: error converting argument 1
stack traceback:
        [C]: in function 'timer_stop'
        /home/mangowang/.config/nvim/lua/utils/terminal/state.lua:79
```

**原因:** `vim.defer_fn` 返回的不是可用於 `vim.fn.timer_stop` 的 timer ID

**✅ 修復:** 使用 `vim.fn.timer_start` 替代 `vim.defer_fn`，並加入 `pcall` 保護

---

### ❌ 問題 2: blink.cmp 配置錯誤
**錯誤訊息:**
```
blink.cmp   cmdline  →  completion  →  menu  →  max_items  Unexpected field in configuration!
blink.cmp   sources  →  providers  →  path  →  match_strategy  Unexpected field in configuration!
```

**原因:** 使用了 blink.cmp 不支援的配置欄位

**✅ 修復:** 移除無效欄位
- 移除 `sources.providers.path.opts.match_strategy`  
- 移除 `cmdline.completion.menu.max_items`

---

### ⚠️ 問題 3: vim.tbl_islist 棄用警告
**錯誤訊息:**
```
vim.tbl_islist is deprecated. Run ":checkhealth vim.deprecated" for more information
```

**原因:** 使用了 Neovim 0.10+ 中已棄用的 API

**✅ 狀態:** 警告來自外部插件，本配置已使用新 API (`vim.bo[buf]` 替代 `nvim_buf_get_option`)

## 🔧 驗證修復

### 1. 手動測試終端功能
```lua
-- 在 Neovim 中執行以下命令測試
:lua require('utils.terminal.manager').toggle_claude_code()
:lua require('utils.terminal.manager').toggle_gemini()  
:lua require('utils.terminal.manager').switch_terminal()
```

### 2. 檢查 blink.cmp 設定
```lua
-- 檢查配置是否正確載入
:lua print(vim.inspect(require('configs.blink')))
```

### 3. 檢查棄用 API
```vim
:checkhealth vim.deprecated
```

## 🚀 效能優化建議

### 終端管理
- 死鎖保護：3 秒自動超時
- 併發控制：防止重複操作
- 資源清理：自動清理無效狀態

### 剪貼板功能  
- 敏感內容檢測：多階段掃描
- 記憶體管理：模組級狀態管理
- 安全措施：全面的輸入驗證

### blink.cmp 補全
- 精確匹配優先：減少拼寫容錯
- 效能優化：限制最大項目數
- UI 一致性：與 NvChad 主題整合

## 🎯 使用建議

### 日常開發
1. 使用 `<leader>cc` 開啟 Claude Code
2. 使用 `<leader>gm` 開啟 Gemini CLI
3. 使用 `<leader>tt` 在兩者間切換
4. 使用 `<C-q>` 在終端模式下關閉當前終端

### 故障恢復
```lua
-- 重置終端狀態
:lua require('utils.terminal.manager').reset()

-- 清理終端狀態
:lua require('utils.terminal.manager').cleanup()

-- 檢查終端狀態
:lua print(vim.inspect(require('utils.terminal.manager').get_status()))
```

### 安全設定
```lua
-- 檢查剪貼板安全設定
:lua require('utils.clipboard').show_config()

-- 安全啟用 OSC 52（如需要）
:lua require('utils.clipboard').enable_osc52_safely()
```

## 📞 支援

如果遇到其他問題：
1. 檢查 `:messages` 獲取詳細錯誤訊息
2. 運行 `:checkhealth` 進行全面健康檢查
3. 查看 `SECURITY_AUDIT_REPORT.md` 了解安全實現
4. 參考 `CLAUDE.md` 了解配置詳情