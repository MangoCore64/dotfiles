# Dotfiles

個人的 vim、tmux、nvim 設定檔案同步 repository。

## 檔案結構

```
.
├── .vimrc              # Vim 設定檔
├── .tmux.conf          # Tmux 設定檔
├── .claude/            # Claude Code 配置目錄
│   └── agents/         # 專業 sub-agent 生態系統
├── nvim/               # Neovim 設定目錄 (NvChad v2.5)
│   ├── init.lua        # NvChad bootstrap 入口
│   ├── lazy-lock.json  # 插件版本鎖定檔
│   ├── docs/           # 📚 開發者文檔體系
│   │   ├── QUICKSTART.md      # 5分鐘快速入門
│   │   ├── USER_GUIDE.md      # 完整使用指南
│   │   ├── ARCHITECTURE.md    # 系統架構文檔
│   │   ├── API_REFERENCE.md   # API 參考手冊
│   │   ├── EXTENDING.md       # 擴展開發指南
│   │   └── TROUBLESHOOTING.md # 故障排除大全
│   ├── tests/          # 🧪 品質保證測試系統
│   │   ├── terminal/   # 終端系統整合測試
│   │   └── clipboard/  # 剪貼簿功能測試
│   ├── scripts/        # 自動化腳本
│   └── lua/            # Lua 設定檔目錄
│       ├── configs/    # 插件設定檔
│       ├── plugins/    # 自定義插件
│       └── utils/      # 高階工具模組
│           ├── terminal/    # 智能終端管理系統
│           ├── clipboard/   # 智能剪貼簿系統
│           └── error-handler.lua # 統一錯誤處理
├── install.sh          # 🔧 智能安裝腳本 (安全性強化)
└── README.md           # 📖 使用說明文件
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

# 自動安裝相依工具（包含 neovim 和 ripgrep）
./install.sh --install-deps

# 強制安裝 neovim
./install.sh --install-neovim

# 安裝 Nerd Fonts（圖示顯示）
./install.sh --install-fonts

# 僅檢查安裝狀態不執行安裝
./install.sh --check-only
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

- **Framework**: 基於 NvChad v2.5
- **Plugin Manager**: lazy.nvim
- **主要功能**:
  - **智能終端管理系統** (Claude Code + Gemini AI 雙終端支援)
  - 智能剪貼簿系統 (<leader>cpr, <leader>cpp)
  - Claude Code AI 助手整合
  - **GitHub Copilot AI 智慧補全** (完美整合 blink.cmp)
  - LSP 自動安裝與配置 (Mason)
  - 現代化的 UI 組件
  - 檔案樹導航
  - 模糊搜尋 (Telescope + ripgrep)
  - 自動會話管理
  - Git 整合
  - Blink.cmp 高效能補全引擎 (Ctrl-j/k 導航, Ctrl-n 手動觸發)

- **AI 輔助功能**:
  - **智能終端管理**: Claude Code 與 Gemini AI 雙終端整合
    - `<leader>cc` - 切換 Claude Code 終端
    - `<leader>og` / `<leader>gm` - 切換 Gemini AI 終端
    - `<leader>tt` - 在 Claude Code 和 Gemini 間切換
    - `<C-q>` - 在終端模式下智能關閉當前終端
  - **GitHub Copilot 整合**: 即時 AI 程式碼建議，與 blink.cmp 無縫整合
  - **Copilot 管理命令**: 
    - `<leader>coa` - GitHub 認證登入
    - `<leader>cos` - 檢查 Copilot 狀態
    - `<leader>coe` - 啟用 Copilot
    - `<leader>cod` - 停用 Copilot
    - `<leader>cor` - 重啟 Copilot 服務
  - **智慧補全體驗**: Copilot 建議顯示在 blink.cmp 選單中，支援高優先級顯示

## 安裝後步驟

### Vim
1. 開啟 vim
2. 執行 `:PlugInstall` 安裝 plugins
3. 重啟 vim

### Tmux
1. 重啟 tmux 或執行 `tmux source-file ~/.tmux.conf`
2. 新的設定立即生效

### Neovim
1. 腳本會自動安裝 neovim (如未安裝)
2. 開啟 nvim，NvChad 會自動安裝所需的 plugins
3. 等待安裝完成
4. 在終端設定中選擇 Nerd Font (如 FiraCode Nerd Font)
5. **GitHub Copilot 設定** (需要 Node.js 16.0+)：
   - 執行 `<leader>coa` 進行 GitHub 認證登入
   - 按照提示完成瀏覽器認證流程
   - 使用 `<leader>cos` 確認 Copilot 狀態為已啟用
6. 測試功能：
   - **智能終端管理**：按 `<leader>cc` 開啟 Claude Code，按 `<leader>og` 開啟 Gemini AI
   - 智能剪貼簿：選取代碼後按 `<leader>cpr`
   - **GitHub Copilot**：編輯程式碼時自動顯示 AI 建議
7. **查閱完整文檔**：
   - 參考 `nvim/docs/` 目錄下的完整文檔系統
   - 🚀 [QUICKSTART.md](nvim/docs/QUICKSTART.md) - 5分鐘快速上手
   - 📚 [USER_GUIDE.md](nvim/docs/USER_GUIDE.md) - 詳細使用指南
   - 🏠 [ARCHITECTURE.md](nvim/docs/ARCHITECTURE.md) - 系統架構設計
   - 🔧 [TROUBLESHOOTING.md](nvim/docs/TROUBLESHOOTING.md) - 完整故障排除指南

## 相依性需求

### 必要工具
- vim
- tmux  
- curl (用於下載 vim-plug)

### 核心工具（自動安裝）
- **Neovim 0.9.0+** (主要編輯器)
  - 支援包管理器安裝 (brew, apt, yum, dnf, pacman)
  - **macOS 優化**：支援 /opt/homebrew/bin/ 路徑自動檢測
  - 支援 AppImage 安裝 (Linux 無權限時)
  - 支援源碼編譯安裝 (最後選項)
  - **終端啟動重試邏輯**：macOS 環境下提高成功率
- **ripgrep** (NvChad 搜尋功能)
  - 支援包管理器安裝
  - 支援預編譯二進制下載
  - 支援 cargo 安裝
- **Node.js 16.0+** (GitHub Copilot 必需)
  - 用於執行 GitHub Copilot AI 服務
  - 安裝方式：https://nodejs.org/ 或包管理器
  - 安裝腳本會自動檢測並提示安裝
- **Nerd Fonts** (圖示顯示)
  - 自動檢測系統字體目錄
  - 智能選擇字體安裝方式
  - **跨平台優化**：支援 macOS 和 Linux 平台

### 🔒 安全性增強 (2025-08)
- **URL 驗證**：下載前驗證所有外部鏈接
- **檔案完整性檢查**：SHA256 校驗
- **權限控制**：腳本權限自動檢查
- **備份系統**：自動時間戳備份現有配置

### AI 功能需求
- **GitHub 帳號** (Copilot 認證)
- **網路連線** (AI 服務通訊)
- **GitHub Copilot 訂閱** (付費服務，學生免費)

### 選用工具
- git (用於 plugin 管理)
- fd (用於更快的檔案搜尋)
- Nerd Fonts (正確顯示圖示)

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

### 工具安裝問題
```bash
# 檢查安裝狀態
./install.sh --check-only

# 強制重新安裝 neovim
./install.sh --install-neovim

# 自動安裝所有缺失工具
./install.sh --install-deps

# 安裝 Nerd Fonts 修復圖示問題
./install.sh --install-fonts
```

### GitHub Copilot 問題
```bash
# 檢查 Copilot 狀態
# 在 nvim 中執行
<leader>cos

# Copilot 認證問題
<leader>coa  # 重新進行 GitHub 認證

# 檢查 Node.js 版本
node --version  # 需要 16.0+

# 重啟 Copilot 服務
<leader>cor

# 如果 Copilot 建議不出現
<leader>coe  # 確保 Copilot 已啟用

# 檢查網路連線
curl -s https://api.github.com/user  # 測試 GitHub API 連線
```

## 自訂設定

如需修改設定，請直接編輯對應的設定檔：
- Vim: `~/.vimrc`
- Tmux: `~/.tmux.conf`  
- Neovim: `~/.config/nvim/init.lua`

## 授權

MIT License

## 📚 開發者文檔

專案現在包含完整的開發者文檔體系，位於 `nvim/docs/` 目錄：

- **[快速入門](nvim/docs/QUICKSTART.md)** - 5分鐘開始使用
- **[使用指南](nvim/docs/USER_GUIDE.md)** - 完整功能介紹
- **[架構文檔](nvim/docs/ARCHITECTURE.md)** - 系統設計說明
- **[故障排除](nvim/docs/TROUBLESHOOTING.md)** - 常見問題解決
- **[擴展開發](nvim/docs/EXTENDING.md)** - 自定義開發指南
- **[API 參考](nvim/docs/API_REFERENCE.md)** - 完整 API 文檔

### 🧪 品質保證
- **自動化測試**：`nvim/tests/` - 終端、剪貼簿功能測試
- **32+ 專業測試檔案**：
  - **終端系統測試** (15+ 測試)：Claude Code/Gemini AI 整合、狀態管理、安全性
  - **剪貼簿系統測試** (8+ 測試)：模組化架構、安全性加強、API 相容性
  - **E2E 測試**：完整工作流程驗證和滲透測試
- **執行測試**：`cd nvim && ./scripts/run_tests.sh` 或 `nvim -c "luafile tests/test_runner.lua"`

## 🔧 開發者工具

### 測試與開發
```bash
# 執行全部測試
cd nvim && ./scripts/run_tests.sh

# 檢查配置健康度
nvim +checkhealth +qa

# 查看詳細日誌
tail -f ~/.local/share/nvim/log
```

### 除錯與監控
- **性能監控**：內建 performance-monitor.lua
- **錯誤處理**：統一 error-handler.lua 系統
- **狀態管理**：terminal/state.lua 和 clipboard/state.lua

---

## 📋 更新記錄

- **2025-08-08**:
  - **文檔全面同步更新**：README.md 和 CLAUDE.md 反映最新架構變更和功能
  - **macOS 優化功能詳細說明**：Homebrew 路徑支援、平台檢測機制、終端重試邏輯
  - **測試系統完整介紹**：32+ 測試檔案、執行指引、E2E 工作流程驗證
  - **安全性功能全面說明**：URL 驗證、SHA256 完整性檢查、權限控制機制
  - **開發者文檔體系整合**：7 個專業文檔、完整 API 參考、模組化架構說明
- **2025-08-07**:
  - **macOS 終端啟動問題修復**：新增 Homebrew 路徑支援和重試邏輯
  - **平台特定優化**：智能檢測 macOS 並應用專用配置
  - **UI 性能優化**：簡化驗證機制，提升響應速度
  - **備份目錄清理**：移除 nvim.backup/ 避免版本控制污染
- **2025-08-06**:
  - **開發者文檔體系建立**：完整的 docs/ 目錄和使用指南
  - **測試系統部署**：品質保證和自動化測試框架
  - **Claude agents 配置優化**：專業 sub-agent 生態系統
- 2025-08-01:
  - **重大配置健檢與安全性修正**
  - 修復 LSP 配置錯誤：移除不存在的 vim.lsp.enable() API
  - 修正 Mason LSP server 名稱錯誤（package names → server names）
  - 更新所有已棄用的 nvim_buf_get_option API 為 vim.bo
  - **安全性增強**：OSC 52 預設禁用，新增敏感內容檢測
  - 重構 terminal-manager.lua 提升穩定性與簡潔性
  - 新增統一錯誤處理系統 (error-handler.lua)
  - 新增配置驗證機制 (config-validator.lua)
  - 實施混合版本管理策略（AI 工具鎖定版本，其他保持彈性）
- 2025-07-31:
  - **智能終端管理系統完整實現**
  - 新增 Claude Code 與 Gemini AI 雙終端支援，支援智能切換
  - 實現終端狀態檢測與同步，修復 buffer 重用問題
  - 新增終端按鍵映射：`<leader>cc`, `<leader>og`, `<leader>tt`, `<C-q>`
  - 修復 Gemini 終端的狀態同步和關閉邏輯
  - 清理調試文檔，保留核心配置文件
- 2025-07-28:
  - **重大更新：GitHub Copilot 與 blink.cmp 完美整合**
  - 新增 GitHub Copilot AI 智慧補全功能，與 blink.cmp 無縫整合
  - 修正 blink.cmp 配置結構錯誤，解決 "Unexpected field" 問題
  - 新增 Copilot 管理按鍵映射：認證、狀態檢查、啟用/停用等
  - 更新安裝腳本：加入 Node.js 依賴檢查和 Copilot 設定指引
  - 完善文檔：新增 AI 功能說明、故障排除和使用指引
- 2025-07-27: 
  - 強化安裝腳本安全性：URL 驗證、檔案完整性檢查、錯誤處理優化
  - 更新 NvChad blink.cmp 配置與文檔同步
- 2025-07-26: 
  - 新增 neovim 和 ripgrep 自動安裝功能，支援多平台和無權限安裝
  - 新增 Nerd Fonts 自動安裝功能，修正圖示顯示問題
  - 修正 vim 插件版本參考和相容性問題
- 2025-07-25: 更新 NvChad 配置，新增 Claude Code 和智能剪貼簿功能
- 2025-07-23: 初始版本，包含 vim、tmux、nvim 設定