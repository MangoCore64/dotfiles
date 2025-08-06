# 快速入門指南

在 5 分鐘內開始使用 Neovim AI 工具整合！

## 🚀 快速安裝

### 1. 前置需求檢查
```bash
# 檢查 Neovim 版本 (需要 >= 0.9.0)
nvim --version

# 安裝 Claude Code CLI (如果還沒安裝)
# 訪問 https://claude.ai/code 獲取安裝指令
```

### 2. 設置 API Key
```bash
# 設置 Claude API Key
export ANTHROPIC_API_KEY="your-api-key-here"

# (可選) 設置 Gemini
# 按照 Gemini CLI 文檔設置
```

## 🎯 必學快捷鍵（只需記住這5個）

| 快捷鍵 | 功能 | 記憶技巧 |
|--------|------|----------|
| `<Space>cc` | Claude Code 開關 | **C**laude **C**ode |
| `<Space>gm` | Gemini 開關 | **G**e**m**ini |
| `<Space>cs` | 發送選中到 Claude | **C**laude **S**end |
| `<Space>tt` | 切換 AI 工具 | **T**oggle **T**erminal |
| `<Esc>` | 關閉浮動視窗 | 通用退出 |

> 💡 `<Space>` 是 leader 鍵

## 🏃 30 秒上手

### 場景 1：詢問 Claude 關於代碼
```
1. 選擇代碼（V 模式）
2. 按 <Space>cs 發送
3. 按 <Space>cc 開啟 Claude
4. 輸入問題，獲得答案
```

### 場景 2：快速切換 AI 工具
```
1. <Space>cc 開啟 Claude
2. <Space>tt 切換到 Gemini
3. <Space>tt 切換回 Claude
```

## 📝 常用工作流程

### 1. 獲取代碼建議
```vim
" 1. 寫一個函數框架
function calculateTotal(items)
  -- TODO: implement
end

" 2. 選擇整個函數 (Vap)
" 3. <Space>cs 發送到 Claude
" 4. <Space>cc 查看建議
```

### 2. 除錯協助
```vim
" 1. 遇到錯誤時，複製錯誤訊息
" 2. <Space>cc 開啟 Claude
" 3. 貼上錯誤，描述問題
" 4. 獲得解決方案
```

### 3. 重構代碼
```vim
" 1. 選擇要重構的代碼
" 2. <Space>cs + <Space>cc
" 3. 輸入: '請幫我重構這段代碼'
" 4. 應用建議的改進
```

## 🎮 互動技巧

### 在終端視窗中
- `i` - 進入插入模式（輸入）
- `<C-\><C-n>` - 進入正常模式（瀏覽）
- `<Esc>` - 關閉視窗

### 複製貼上
- 終端內複製：正常模式下 `y`
- 貼上到終端：插入模式下 `<C-v>`
- 從終端複製到編輯器：選擇後 `y`

## 🆘 遇到問題？

### Claude Code 無法開啟
```vim
" 1. 檢查健康狀態
:checkhealth

" 2. 確認 Claude 已安裝
:!which claude

" 3. 重置終端
<Space>tr
```

### 性能問題
```vim
" 查看性能狀態
:lua require('utils.performance-monitor').show_status()
```

### 終端凍結
```
1. 按 <Esc> 嘗試關閉
2. 使用 <Space>tr 重置
3. 重啟 Neovim（最後手段）
```

## 💡 專業提示

### 1. 檔案參考模式
```vim
" 當討論特定代碼位置時
" 1. 選擇代碼
" 2. <Space>cpr (複製參考)
" 3. 貼上顯示為: filename.lua:10-25
```

### 2. 保持工具開啟
```vim
" Claude 會保持對話上下文
" 不需要每次都關閉
" 切換到其他緩衝區繼續工作
```

### 3. 使用分割視窗
```vim
" 垂直分割後使用 AI
:vsplit
<Space>cc
" 現在可以邊看代碼邊對話
```

## 🎯 下一步

1. **探索更多功能**
   - 閱讀完整的 [USER_GUIDE.md](USER_GUIDE.md)
   - 嘗試性能監控工具

2. **自定義配置**
   - 調整快捷鍵（`lua/mappings.lua`）
   - 修改視窗大小

3. **整合到工作流程**
   - 養成使用 AI 輔助的習慣
   - 探索不同的使用場景

---

🎉 恭喜！您已經掌握了基本操作。開始享受 AI 輔助開發的樂趣吧！