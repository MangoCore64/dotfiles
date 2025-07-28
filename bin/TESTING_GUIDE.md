# Session-Per-Project 測試指南

## 修復內容總結

### 1. TMux-Resurrect 配置修復 ✅

**修復項目：**
- ✅ 自動保存：每 15 分鐘自動保存會話
- ✅ 自動恢復：啟動時自動恢復會話
- ✅ Pane 內容保存：保存終端內容
- ✅ 程序保存：保存 ssh、git 等程序狀態

**驗證方法：**
```bash
# 檢查配置狀態
tmux show-options -g | grep -E "continuum|resurrect"

# 手動保存測試（可選，會自動保存）
tmux run-shell '~/.tmux/plugins/tmux-resurrect/scripts/save.sh'
```

### 2. Persistence.nvim 配置修復 ✅

**修復項目：**
- ✅ SessionOptions：添加 "buffers,curdir,folds,help,tabpages,winsize" 等選項
- ✅ 多 Buffer 支援：現在能正確保存和恢復所有開啟的 buffer
- ✅ Git 分支隔離：不同分支有獨立的會話
- ✅ 自動保存：退出時自動保存會話

**按鍵映射：**
- `<leader>ps` - 立即保存當前會話
- `<leader>pl` - 載入當前目錄和 git 分支的會話
- `<leader>pL` - 載入最後一次會話
- `<leader>pd` - 停止會話管理（不自動保存）

## 完整測試流程

### 步驟 1：基礎測試

1. **啟動測試腳本：**
   ```bash
   cd ~/dotfiles
   ./bin/test-complete-workflow
   ```

2. **在 nvim 中測試多 Buffer：**
   ```vim
   :e file1.txt
   :e file2.txt  
   :e file3.txt
   :ls                    " 確認有 3 個 buffer
   <leader>ps             " 保存會話
   :qa                    " 退出
   
   # 重新啟動 nvim
   nvim .
   <leader>pl             " 載入會話
   :ls                    " 應該看到 3 個 buffer
   ```

### 步驟 2：Git 分支測試

1. **在不同分支建立會話：**
   ```bash
   # 主分支
   git checkout master
   nvim .
   # 開啟一些檔案，<leader>ps 保存
   
   # 新分支  
   git checkout -b feature-test
   nvim .
   # 開啟不同檔案，<leader>ps 保存
   
   # 切回主分支
   git checkout master  
   nvim .
   <leader>pl             " 應該載入主分支的會話
   ```

### 步驟 3：TMux Session 管理測試

1. **使用專案模板：**
   ```bash
   ./bin/tmux-project-template test-project ~/test-project-path
   chmod +x ~/bin/tmux-test-project
   ~/bin/tmux-test-project
   ```

2. **驗證 TMux 自動恢復：**
   ```bash
   # 殺掉 tmux server（模擬重啟）
   tmux kill-server
   
   # 重新啟動 tmux
   tmux new-session
   # 應該自動恢復之前的會話
   ```

## 故障排除

### 問題 1：只保存/載入一個 Buffer

**原因：** SessionOptions 設定不完整  
**解決：** 已在 `~/.config/nvim/lua/options.lua` 中修復

### 問題 2：TMux Continuum 狀態顯示 "off"

**原因：** 配置未重載  
**解決：** 
```bash
tmux source-file ~/.tmux.conf
tmux run-shell '~/.tmux/plugins/tmux-continuum/scripts/continuum_status.sh'
```

### 問題 3：會話沒有基於 Git 分支隔離

**原因：** Persistence.nvim 的 branch 選項未啟用  
**解決：** 已在配置中設定 `branch = true`

### 問題 4：按 `<leader>ss` 進入 Insert Mode

**原因：** `s` 是 vim 的替換命令  
**解決：** 已改用 `<leader>ps/pl/pL/pd` 按鍵映射

## 使用最佳實踐

### 日常工作流程

1. **啟動專案：**
   ```bash
   cd ~/project-directory
   tmux new-session -s project-name
   nvim .
   <leader>pl  # 載入專案會話
   ```

2. **專案切換：**
   ```bash
   tmux switch-client -t other-project
   # 或建立新的專案會話
   ~/bin/tmux-project-template project-name ~/project-path
   ```

3. **結束工作：**
   ```bash
   # nvim 會自動保存會話
   # tmux 每 15 分鐘自動保存
   # 或手動保存：Ctrl-a + Ctrl-s
   ```

### 進階功能

- **分支特定會話：** 不同 git 分支自動載入不同的 nvim 會話
- **專案模板：** 使用 `tmux-project-template` 快速建立標準專案結構
- **自動恢復：** 重啟後自動恢復所有 tmux session 和 nvim 會話

## 配置文件位置

- TMux 設定：`~/.tmux.conf`
- Nvim 主設定：`~/.config/nvim/lua/options.lua`
- Persistence 設定：`~/.config/nvim/lua/plugins/init.lua`
- 會話檔案：`~/.local/state/nvim/sessions/`
- TMux 會話備份：`~/.local/share/tmux/resurrect/`