# tmux Session-Per-Project 工作流程指南

## 概述

這套工具實現了現代的 tmux + Neovim 會話管理，採用業界標準的 session-per-project 做法。

## 核心特色

- 🎯 **每專案獨立 session**：避免專案間干擾
- 🔄 **自動會話恢復**：tmux-resurrect + persistence.nvim 雙層恢復
- 🌿 **Git 分支感知**：不同分支不同 nvim 會話
- 📂 **目錄自動管理**：基於工作目錄的會話保存/載入
- 🧹 **智能 Buffer 清理**：自動過濾目錄和無效 buffer

## 快速開始

### 1. 建立專案腳本

```bash
# 使用範本生成器建立專案腳本 (存放在 ~/bin/)
./tmux-project-template myapp ~/projects/myapp
./tmux-project-template webapp ~/dev/webapp
```

### 2. 啟動專案

```bash
# 方式 1: 直接執行
~/bin/tmux-myapp

# 方式 2: 建立 alias (推薦)
echo "alias myapp='~/bin/tmux-myapp'" >> ~/.bashrc
source ~/.bashrc
myapp  # 一鍵啟動！
```

### 3. 專案結構

每個專案 session 包含 4 個標準 windows：

```
myapp session
├── window 0: editor  (nvim .)
├── window 1: git     (git 操作)
├── window 2: server  (開發伺服器)
└── window 3: term    (一般終端)
```

## 會話管理

### Neovim 會話 (persistence.nvim)

```vim
" 手動管理 (通常不需要，會自動處理)
<leader>ps  " 保存當前會話
<leader>pl  " 載入目錄會話 (含 git 分支)
<leader>pL  " 載入最後會話
<leader>pd  " 停止自動保存
```

### tmux 會話 (tmux-resurrect)

```bash
# 手動保存/恢復 (通常不需要，continuum 會自動處理)
Ctrl-a + Ctrl-s  # 保存所有 sessions
Ctrl-a + Ctrl-r  # 恢復所有 sessions
```

## 工作流程範例

### 日常開發

```bash
# 1. 啟動專案環境
myapp

# 2. 自動發生：
#    - tmux 建立/連接 myapp session
#    - persistence.nvim 載入專案會話
#    - 4 個 windows 準備就緒

# 3. 切換專案
webapp  # 切換到另一個專案

# 4. 系統重啟後
#    - tmux-continuum 自動恢復所有 sessions
#    - persistence.nvim 自動載入各專案會話
```

### Git 分支工作

```bash
# 在不同分支工作，nvim 會話自動隔離
git checkout feature-a  # persistence.nvim 自動切換到 feature-a 會話
git checkout main       # 自動切換到 main 分支會話
```

## 最佳實践

### 1. 專案腳本管理

```bash
# ✅ 推薦：使用範本生成器
./tmux-project-template myproject ~/path/to/project

# ❌ 避免：手動複製修改 (容易出錯)
```

### 2. 目錄結構

```bash
# ✅ 推薦：統一的專案目錄結構
~/projects/
├── myapp/      (對應 tmux-myapp)
├── webapp/     (對應 tmux-webapp)
└── api/        (對應 tmux-api)

# 或
~/dev/
├── frontend/   (對應 tmux-frontend)
└── backend/    (對應 tmux-backend)
```

### 3. 自定義開發伺服器

編輯生成的專案腳本，在 server window 中取消註解對應命令：

```bash
# Node.js
tmux send-keys -t $SESSION:2 'npm run dev' C-m

# Python/Django
tmux send-keys -t $SESSION:2 'python manage.py runserver' C-m

# Ruby/Rails
tmux send-keys -t $SESSION:2 'rails server' C-m
```

## 故障排除

### Q: nvim 會話沒有自動載入？

A: 檢查 persistence.nvim 配置，確保 `branch = true` 且在正確目錄。

### Q: tmux session 沒有恢復？

A: 檢查 tmux-continuum 是否啟用：`tmux show-options -g @continuum-restore`

### Q: 專案腳本找不到？

A: 確保 ~/bin 在 PATH 中：`echo $PATH | grep "$HOME/bin"`

## 升級與維護

- 專案腳本存放在 `~/bin/tmux-*`，不納入 dotfiles 版控
- dotfiles 只包含範本生成器和配置文件
- 升級時重新執行範本生成器即可更新所有專案腳本