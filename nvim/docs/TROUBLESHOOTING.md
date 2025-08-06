# 故障排除指南

本指南幫助您診斷和解決使用 Neovim AI 工具整合時可能遇到的問題。

## 🔍 診斷工具

### 1. 健康檢查
```vim
" 系統健康檢查
:checkhealth

" 終端管理器健康檢查
:lua require('utils.terminal.manager').health_check()
```

### 2. 查看日誌
```vim
" 查看 Neovim 訊息
:messages

" 查看詳細錯誤
:lua vim.notify(vim.inspect(vim.v.errmsg))
```

### 3. 性能診斷
```vim
" 性能狀態
:lua require('utils.performance-monitor').show_status()

" 詳細報告
:lua require('utils.performance-monitor').show_report()
```

## 🚨 常見問題與解決方案

### 1. Claude Code 無法開啟

#### 症狀
- 按 `<leader>cc` 沒有反應
- 出現錯誤訊息 "command not found"

#### 診斷步驟
```bash
# 1. 檢查 Claude 是否已安裝
which claude

# 2. 檢查執行權限
ls -la ~/bin/claude

# 3. 測試直接執行
~/bin/claude --version
```

#### 解決方案
```bash
# 如果未安裝
# 訪問 https://claude.ai/code 獲取安裝指令

# 如果權限問題
chmod +x ~/bin/claude

# 如果路徑問題，添加到 PATH
export PATH="$HOME/bin:$PATH"
```

### 2. API Key 錯誤

#### 症狀
- Claude 開啟但顯示認證錯誤
- 提示 "Invalid API key"

#### 解決方案
```bash
# 設置正確的 API key
export ANTHROPIC_API_KEY="sk-ant-..."

# 永久設置（添加到 ~/.bashrc 或 ~/.zshrc）
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
source ~/.bashrc
```

### 3. 終端視窗凍結

#### 症狀
- 終端無響應
- 無法輸入或關閉

#### 快速修復
```vim
" 1. 強制退出終端模式
<C-\><C-n>

" 2. 關閉視窗
:q

" 3. 重置終端管理器
:lua require('utils.terminal.manager').reset()
```

#### 預防措施
- 避免在終端中運行長時間阻塞的命令
- 定期保存對話內容
- 使用健康檢查監控狀態

### 4. 切換功能失效

#### 症狀
- `<leader>tt` 無法切換
- 終端狀態不一致

#### 診斷
```vim
" 查看當前狀態
:lua print(vim.inspect(require('utils.terminal.manager').get_status()))
```

#### 修復步驟
```vim
" 1. 清理無效狀態
:lua require('utils.terminal.manager').cleanup()

" 2. 如果仍有問題，完全重置
:lua require('utils.terminal.manager').reset()

" 3. 重新開始
<leader>cc
```

### 5. 性能問題

#### 症狀
- 啟動變慢
- 切換延遲增加
- 記憶體使用過高

#### 診斷
```vim
" 執行性能基準測試
:lua require('utils.performance-monitor').run_benchmarks()

" 查看記憶體使用
:lua local m = require('utils.performance-monitor').get_memory_usage()
:lua print(string.format("Memory: %.1f MB", m.rss_mb))
```

#### 優化建議
1. **減少插件數量**
   ```vim
   " 檢查載入的插件
   :Lazy profile
   ```

2. **清理緩存**
   ```vim
   " 清理性能數據
   :lua require('utils.performance-monitor').reset_data()
   ```

3. **調整監控頻率**
   ```lua
   -- 在配置中降低監控頻率
   require('utils.performance-monitor').update_config({
     benchmarks = {
       memory_check_interval = 120  -- 改為 2 分鐘
     }
   })
   ```

### 6. 剪貼板問題

#### 症狀
- 無法複製到系統剪貼板
- SSH/VM 環境下剪貼板失效

#### 解決方案
```vim
" 1. 檢查剪貼板支援
:echo has('clipboard')

" 2. 如果在 SSH 中，確保 OSC 52 支援
" 配置終端模擬器支援 OSC 52

" 3. 使用檔案參考模式作為替代
<leader>cr
```

### 7. 浮動視窗顯示問題

#### 症狀
- 視窗大小不正確
- 邊框顯示異常
- 位置偏移

#### 調整方法
```lua
-- 修改 lua/utils/terminal/ui.lua
local default_config = {
  relative = "editor",
  width = 0.8,      -- 調整寬度
  height = 0.8,     -- 調整高度
  border = "single", -- 改變邊框樣式
}
```

## 🔧 進階診斷

### 1. 除錯模式
```lua
-- 啟用詳細日誌
require('utils.performance-monitor').update_config({
  monitoring = {
    detailed_logging = true
  }
})
```

### 2. 手動狀態檢查
```lua
-- 檢查終端狀態
local state = require('utils.terminal.state').get_status()
print(vim.inspect(state))

-- 驗證狀態隔離
local valid, msg = require('utils.terminal.state').validate_state_isolation()
print(valid and "狀態正常" or msg)
```

### 3. 強制恢復
```lua
-- 強制錯誤恢復
require('utils.terminal.manager').force_recovery()
```

## 📊 錯誤代碼參考

| 錯誤代碼 | 含義 | 解決方法 |
|---------|------|---------|
| 129 | SIGHUP（終端關閉） | 正常行為，無需處理 |
| TIMEOUT | 操作超時 | 檢查網路，重試操作 |
| INVALID_STATE | 狀態無效 | 執行 cleanup() |
| RESOURCE_CONFLICT | 資源衝突 | 重置終端 |
| COMMAND_FAILED | 命令失敗 | 檢查命令和路徑 |

## 🆘 緊急恢復流程

如果遇到嚴重問題，按照以下步驟恢復：

### 1. 軟重置
```vim
:lua require('utils.terminal.manager').cleanup()
:lua require('utils.terminal.manager').reset()
```

### 2. 硬重置
```vim
" 1. 關閉所有終端視窗
:qa

" 2. 重啟 Neovim
:qa!
nvim

" 3. 清理狀態
:lua require('utils.terminal.state').reset()
```

### 3. 完全重置
```bash
# 1. 備份配置
cp -r ~/.config/nvim ~/.config/nvim.backup

# 2. 清理緩存
rm -rf ~/.local/share/nvim/lazy/nvim-cmp
rm -rf ~/.cache/nvim

# 3. 重新安裝插件
nvim +Lazy sync
```

## 📝 問題回報

如果問題持續存在，請收集以下資訊：

### 1. 系統資訊
```vim
:version
:checkhealth
```

### 2. 錯誤日誌
```vim
:messages
:lua require('utils.terminal.manager').debug_info()
```

### 3. 重現步驟
1. 詳細描述操作步驟
2. 預期行為
3. 實際結果
4. 錯誤訊息（如果有）

### 4. 提交問題
- GitHub Issues
- 包含所有收集的資訊
- 使用問題模板

## 💡 預防建議

### 1. 定期維護
- 每週執行健康檢查
- 監控性能趨勢
- 更新相依套件

### 2. 良好習慣
- 不要同時開啟過多終端
- 定期清理未使用的緩衝區
- 保持系統更新

### 3. 備份策略
- 定期備份配置
- 使用版本控制
- 記錄自定義修改

## 🎯 快速檢查清單

遇到問題時，依序檢查：

- [ ] Claude/Gemini CLI 已正確安裝？
- [ ] API Key 已設置？
- [ ] 執行權限正確？
- [ ] 路徑配置正確？
- [ ] Neovim 版本 >= 0.9.0？
- [ ] 健康檢查通過？
- [ ] 是否有錯誤訊息？
- [ ] 嘗試過重置？

---

記住：大多數問題都可以通過重置和重啟解決。如果問題持續，不要猶豫尋求協助！