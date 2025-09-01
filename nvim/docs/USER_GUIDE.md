# Neovim 配置使用指南

## 簡介

歡迎使用這個專為開發效率優化的 Neovim 配置！本配置採用**簡潔外部工具整合**方式，通過 tmux 視窗提供 Claude Code 和 Gemini 等 AI 工具的便捷存取。

> **✨ 設計理念**: 遵循 Linus "Do one thing well" 原則，每個工具各司其職，Neovim 專注編輯，AI 工具在外部視窗運行。

## 主要功能

### 🤖 AI 工具整合
- **Claude Code** - Anthropic 的官方 CLI 工具
- **Gemini** - Google 的 AI 助手 CLI
- **外部 tmux 視窗** - 簡潔的視窗管理
- **便捷按鍵** - 一鍵開啟 AI 工具

### 📋 智能剪貼板
- 檔案參考模式（節省 token）
- 敏感資訊自動過濾
- 大型選擇智能分段
- OSC 52 支援（SSH/VM 相容）

### 🚀 性能優化
- 快速啟動（延遲載入）
- 外部工具不影響編輯器性能
- 簡潔架構降低資源消耗

## 快速開始

### 系統需求
- Neovim >= 0.9.0
- Unix-like 系統（Linux/macOS）
- Claude Code CLI（需要 API key）
- Gemini CLI（可選）

### 基本操作

#### AI 工具快捷鍵
| 快捷鍵 | 功能 | 說明 |
|--------|------|------|
| `<leader>cc` | 開啟 Claude Code | 在新 tmux 視窗中開啟 Claude CLI |
| `<leader>gm` | 開啟 Gemini | 在新 tmux 視窗中開啟 Gemini CLI |

#### 剪貼板操作
| 快捷鍵 | 功能 | 說明 |
|--------|------|------|
| `<leader>cs` | 發送到 Claude | 將選中內容發送到 Claude |
| `<leader>cr` | 檔案參考模式 | 複製為 `path:line` 格式 |
| `<leader>cp` | 完整內容複製 | 自動分段處理 |

**說明**：所有快捷鍵定義在 `lua/mappings.lua` 中。

### 工作流程範例

#### 1. 使用 Claude Code 輔助編碼
```
1. 在編輯器中選擇要詢問的代碼
2. 按 <leader>cs 發送到 Claude
3. 按 <leader>cc 開啟 Claude Code（新 tmux 視窗）
4. 在 tmux 視窗中與 Claude 互動
5. 使用 tmux 快捷鍵切換回編輯器視窗
```

#### 2. 使用多個 AI 工具
```
1. 按 <leader>cc 開啟 Claude Code
2. 按 <leader>gm 開啟 Gemini
3. 使用 tmux 快捷鍵在不同視窗間切換
```

#### 3. 使用檔案參考模式
```
1. 視覺模式選擇多行代碼
2. 按 <leader>cr 複製參考
3. 貼上時會顯示為 "filename.lua:10-25"
4. AI 工具可以理解這個參考格式
```

## 進階功能

### 系統診斷

#### 健康檢查
使用 Neovim 內建健康檢查：
```vim
:checkhealth
```

#### 剪貼板診斷
檢查剪貼板功能狀態：
```vim
:lua require('utils.clipboard').diagnose_clipboard()
```

### 自定義配置

#### 修改快捷鍵
編輯 `lua/mappings.lua`：
```lua
-- 自定義 Claude Code 快捷鍵
map("n", "<leader>ai", function()
  local cwd = vim.fn.getcwd()
  vim.fn.system('tmux new-window -c "' .. cwd .. '" "claude"')
  vim.notify("Opened Claude CLI in new tmux window", vim.log.levels.INFO)
end, { desc = "Open Claude CLI" })
```

#### 調整 tmux 視窗行為
可以修改 `lua/mappings.lua` 中的命令，例如使用不同的 tmux 選項：
```lua
-- 在當前 pane 分割而不是新視窗
vim.fn.system('tmux split-window "claude"')
```

## 常見使用場景

### 1. 代碼審查
- 選擇要審查的代碼
- 使用 `<leader>cs` 發送到 Claude
- 詢問代碼改進建議

### 2. 除錯協助
- 複製錯誤訊息
- 開啟 AI 工具
- 貼上錯誤並尋求解決方案

### 3. 文檔生成
- 選擇函數或類別
- 使用檔案參考模式
- 請求 AI 生成文檔

### 4. 重構建議
- 選擇要重構的代碼段
- 發送到 AI 工具
- 獲取重構建議

## 最佳實踐

### 1. 使用檔案參考模式
當討論特定代碼位置時，使用 `<leader>cr` 可以：
- 節省 token 使用量
- 提供精確的位置資訊
- 方便後續查找

### 2. 管理 tmux 視窗
- 不使用時關閉 tmux 視窗以釋放資源
- 使用 tmux 的原生管理功能
- 定期執行 Neovim 健康檢查

### 3. 性能優化
- 外部工具不會影響 Neovim 性能
- 保持 Neovim 專注於編輯功能
- 必要時重啟 Neovim 以清理狀態

### 4. 安全注意事項
- 剪貼板會自動過濾敏感資訊
- 但仍需注意不要分享機密代碼
- 定期檢查 AI 工具的權限設置

## 提示與技巧

### 快速切換工作流
1. 使用 tmux 快捷鍵（如 Ctrl-a + 數字）在視窗間切換
2. 保持常用工具開啟以加快訪問
3. 利用 tmux 的多視窗功能同時工作

### 高效複製貼上
1. 大段代碼使用檔案參考模式
2. 小段代碼直接複製
3. 利用智能分段處理超長內容

### tmux 視窗管理
1. 使用 tmux 原生快捷鍵管理視窗
2. Ctrl-a + c 創建新視窗
3. Ctrl-a + 數字 切換到指定視窗
4. Ctrl-a + & 關閉當前視窗

## 獲取幫助

### 相關文檔
- **[架構文檔](ARCHITECTURE.md)** - 系統整體架構設計
- **[快速開始](QUICKSTART.md)** - 5分鐘快速上手
- **[故障排除](TROUBLESHOOTING.md)** - 常見問題解決方案
- **[API參考](API_REFERENCE.md)** - 完整API文檔
- **[擴展指南](EXTENDING.md)** - 自定義配置方法

### 內建幫助
- `:checkhealth` - 檢查系統健康狀態
- `:h terminal` - Neovim 終端幫助
- `:messages` - 查看系統訊息

### 問題診斷
1. **常見問題**：先查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. **健康檢查**：執行系統內建診斷
3. **性能問題**：查看 [ARCHITECTURE.md](ARCHITECTURE.md) 的性能優化部分
4. **API使用**：參考 [API_REFERENCE.md](API_REFERENCE.md)

### 開發支援
- **自定義配置**：參考 [EXTENDING.md](EXTENDING.md)
- **架構理解**：閱讀 [ARCHITECTURE.md](ARCHITECTURE.md)
- **提交問題**：使用 GitHub Issues

## 結語

這個配置旨在提供簡潔高效的開發體驗。通過外部工具整合和優化的工作流程，讓您的開發效率大幅提升。記得善用 tmux 和 Neovim 的原生功能，並根據自己的需求進行自定義！

祝您編碼愉快！ 🚀