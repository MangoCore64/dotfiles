# Neovim AI 工具整合使用指南

## 簡介

歡迎使用這個專為 AI 輔助開發優化的 Neovim 配置！本配置採用**輕量適配器架構** (Plan A)，提供了與 Claude Code 和 Gemini 的高效整合，讓您能在編輯器內直接使用這些強大的 AI 工具。

> **✨ 架構亮點**: 採用純模組化設計，Claude 適配器精簡50%、Gemini 適配器精簡34%，同時保持100%向後相容性。

## 主要功能

### 🤖 AI 工具整合
- **Claude Code** - Anthropic 的官方 CLI 工具
- **Gemini** - Google 的 AI 助手 CLI
- 統一的浮動視窗介面
- 智能終端切換
- 自動錯誤恢復

### 📋 智能剪貼板
- 檔案參考模式（節省 token）
- 敏感資訊自動過濾
- 大型選擇智能分段
- OSC 52 支援（SSH/VM 相容）

### 🚀 性能優化
- 快速啟動（延遲載入）
- 終端切換 < 200ms
- 記憶體自動管理
- 性能監控和報告

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
| `<leader>cc` | 開啟/關閉 Claude Code | 在浮動視窗中顯示 Claude Code |
| `<leader>gm` | 開啟/關閉 Gemini | 在浮動視窗中顯示 Gemini |
| `<leader>tt` | 智能切換 | 在 Claude 和 Gemini 間切換 |
| `<leader>ts` | 顯示狀態 | 查看終端管理器狀態 |
| `<leader>tr` | 重置終端 | 重置所有終端狀態 |

#### 剪貼板操作
| 快捷鍵 | 功能 | 說明 |
|--------|------|------|
| `<leader>cs` | 發送到 Claude | 將選中內容發送到 Claude |
| `<leader>cr` | 檔案參考模式 | 複製為 `path:line` 格式 |
| `<leader>cp` | 完整內容複製 | 自動分段處理 |

**說明**：剪貼板快捷鍵定義在 `lua/mappings.lua` 中，終端快捷鍵定義在 `lua/plugins/init.lua` 中。

### 工作流程範例

#### 1. 使用 Claude Code 輔助編碼
```
1. 在編輯器中選擇要詢問的代碼
2. 按 <leader>cs 發送到 Claude
3. 按 <leader>cc 開啟 Claude Code
4. 在浮動視窗中與 Claude 互動
5. 按 <Esc> 或 <leader>cc 關閉視窗
```

#### 2. 在 AI 工具間切換
```
1. 按 <leader>cc 開啟 Claude Code
2. 按 <leader>tt 切換到 Gemini
3. 按 <leader>tt 切換回 Claude Code
```

#### 3. 使用檔案參考模式
```
1. 視覺模式選擇多行代碼
2. 按 <leader>cr 複製參考
3. 貼上時會顯示為 "filename.lua:10-25"
4. AI 工具可以理解這個參考格式
```

## 進階功能

### 終端管理

#### 健康檢查
執行健康檢查以診斷問題：
```vim
:lua require('utils.terminal.manager').health_check()
```

#### 查看統計資訊
查看操作統計和性能數據：
```vim
:lua require('utils.terminal.manager').get_statistics()
```

### 性能監控

#### 即時狀態
```vim
:lua require('utils.performance-monitor').show_status()
```

#### 詳細報告
```vim
:lua require('utils.performance-monitor').show_report()
```

#### 性能基準測試
```vim
:lua require('utils.performance-monitor').run_benchmarks()
```

### 自定義配置

#### 修改快捷鍵
編輯 `lua/mappings.lua`：
```lua
-- 自定義 Claude Code 快捷鍵
map("n", "<leader>ai", function()
  require("utils.terminal.manager").toggle_claude_code()
end, { desc = "Toggle Claude Code" })
```

#### 調整浮動視窗大小
修改 `lua/utils/terminal/ui.lua` 中的預設配置：
```lua
local default_config = {
  relative = "editor",
  width = 0.9,    -- 90% 寬度
  height = 0.9,   -- 90% 高度
  border = "rounded",
}
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

### 2. 管理終端資源
- 不使用時關閉終端以釋放資源
- 定期執行健康檢查
- 遇到問題時使用重置功能

### 3. 性能優化
- 監控記憶體使用情況
- 注意啟動時間變化
- 定期查看性能報告

### 4. 安全注意事項
- 剪貼板會自動過濾敏感資訊
- 但仍需注意不要分享機密代碼
- 定期檢查 AI 工具的權限設置

## 提示與技巧

### 快速切換工作流
1. 使用 `<leader>tt` 在工具間快速切換
2. 保持常用工具開啟以加快訪問
3. 利用浮動視窗的透明背景查看代碼

### 高效複製貼上
1. 大段代碼使用檔案參考模式
2. 小段代碼直接複製
3. 利用智能分段處理超長內容

### 終端視窗管理
1. 使用 `<C-w>` 相關快捷鍵調整視窗
2. 在終端內使用 `<C-\><C-n>` 進入正常模式
3. 使用 `i` 或 `a` 返回終端模式

## 獲取幫助

### 相關文檔
- **[架構文檔](ARCHITECTURE.md)** - 系統整體架構設計
- **[終端架構](TERMINAL_ARCHITECTURE.md)** - 終端管理詳細架構
- **[快速開始](QUICKSTART.md)** - 5分鐘快速上手
- **[故障排除](TROUBLESHOOTING.md)** - 常見問題解決方案
- **[API參考](API_REFERENCE.md)** - 完整API文檔
- **[擴展指南](EXTENDING.md)** - 新增AI工具的方法

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
- **添加新工具**：參考 [EXTENDING.md](EXTENDING.md)
- **架構理解**：閱讀 [TERMINAL_ARCHITECTURE.md](TERMINAL_ARCHITECTURE.md)
- **提交問題**：使用 GitHub Issues

## 結語

這個配置旨在提供最佳的 AI 輔助開發體驗。通過整合強大的 AI 工具和優化的工作流程，讓您的開發效率大幅提升。記得經常探索新功能，並根據自己的需求進行自定義！

祝您編碼愉快！ 🚀