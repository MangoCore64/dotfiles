# Dotfiles

個人的 vim、tmux、nvim 設定檔案同步 repository。

## 檔案結構

```
.
├── .vimrc              # Vim 設定檔
├── .tmux.conf          # Tmux 設定檔
├── nvim/               # Neovim 設定目錄
│   ├── init.lua        # Neovim 主設定檔
│   ├── coc-settings.json
│   ├── lazy-lock.json
│   └── lua/            # Lua 設定檔目錄
├── install.sh          # 自動安裝腳本
└── README.md           # 說明文件
```

## 快速安裝

### 方法一：使用安裝腳本（推薦）

```bash
# Clone repository
git clone https://github.com/MineWang/dotfiles.git
cd dotfiles

# 安裝所有設定
./install.sh

# 或選擇性安裝
./install.sh --vim    # 僅安裝 vim 設定
./install.sh --tmux   # 僅安裝 tmux 設定
./install.sh --nvim   # 僅安裝 nvim 設定
```

### 方法二：手動安裝

```bash
# Clone repository
git clone https://github.com/MineWang/dotfiles.git
cd dotfiles

# 備份現有設定（建議）
cp ~/.vimrc ~/.vimrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
cp ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
cp -r ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# 複製設定檔
cp .vimrc ~/
cp .tmux.conf ~/
mkdir -p ~/.config
cp -r nvim ~/.config/
```

## 設定說明

### Vim 設定特色

- **Plugin Manager**: vim-plug
- **主要 Plugins**:
  - ALE: 語法檢查與自動修復
  - fzf: 模糊搜尋
  - vim-gitgutter: Git 差異顯示
  - lightline: 狀態列美化
  - PaperColor: 主題
  - Codeium: AI 程式碼補全
  - Claude.vim: Claude AI 整合

- **性能優化**: 延遲載入、快取優化
- **按鍵映射**: Leader key 設為 `,`
- **安全增強**: 禁用不安全功能

### Tmux 設定特色

- **前綴鍵**: `Ctrl-a` (取代預設的 `Ctrl-b`)
- **Vi 模式**: 啟用 vi 風格的按鍵綁定
- **滑鼠支援**: 啟用滑鼠操作
- **預設 Shell**: bash

### Neovim 設定特色

- **Plugin Manager**: lazy.nvim
- **主要功能**:
  - 現代化的 UI 組件
  - LSP 整合
  - 檔案樹導航
  - 模糊搜尋
  - 自動會話管理
  - Git 整合

## 安裝後步驟

### Vim
1. 開啟 vim
2. 執行 `:PlugInstall` 安裝 plugins
3. 重啟 vim

### Tmux
1. 重啟 tmux 或執行 `tmux source-file ~/.tmux.conf`
2. 新的設定立即生效

### Neovim
1. 開啟 nvim
2. Lazy.nvim 會自動安裝所需的 plugins
3. 等待安裝完成

## 相依性需求

### 必要工具
- vim
- tmux
- curl (用於下載 vim-plug)

### 選用工具
- neovim (如需使用 nvim 設定)
- git (用於 plugin 管理)
- ripgrep (用於更好的搜尋體驗)
- fd (用於更快的檔案搜尋)

## 故障排除

### Vim Plugins 安裝失敗
```bash
# 手動安裝 vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# 重新安裝 plugins
vim +PlugInstall +qall
```

### Tmux 設定未生效
```bash
# 重新載入設定
tmux source-file ~/.tmux.conf

# 或重啟 tmux
tmux kill-server
tmux
```

### Neovim 錯誤
```bash
# 清除 nvim 快取
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim

# 重新開啟 nvim
nvim
```

## 自訂設定

如需修改設定，請直接編輯對應的設定檔：
- Vim: `~/.vimrc`
- Tmux: `~/.tmux.conf`  
- Neovim: `~/.config/nvim/init.lua`

## 授權

MIT License

## 更新記錄

- 2025-07-23: 初始版本，包含 vim、tmux、nvim 設定