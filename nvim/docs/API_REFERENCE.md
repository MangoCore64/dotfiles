# API 參考文檔

本文檔提供 Neovim AI 工具整合系統的完整 API 參考。

## 📋 目錄

- [Terminal Manager API](#terminal-manager-api)
- [Terminal Adapters API](#terminal-adapters-api)
- [Unified Terminal API](#unified-terminal-api)
- [State Management API](#state-management-api)
- [Clipboard API](#clipboard-api)
- [Performance Monitor API](#performance-monitor-api)
- [Error Handler API](#error-handler-api)

## 🔧 Terminal Manager API

### `require('utils.terminal.manager')`

主要的終端協調器，管理所有 AI 工具終端。

#### 核心操作

##### `toggle_claude_code()`
開啟或關閉 Claude Code 終端。

```lua
local success = require('utils.terminal.manager').toggle_claude_code()
```

**返回值**：
- `boolean` - 操作是否成功

**行為**：
- 如果 Claude Code 已開啟 → 關閉
- 如果 Claude Code 未開啟 → 開啟並隱藏其他終端

##### `toggle_gemini()`
開啟或關閉 Gemini 終端。

```lua
local success = require('utils.terminal.manager').toggle_gemini()
```

**返回值**：
- `boolean` - 操作是否成功

##### `switch_terminal()`
智能切換終端。

```lua
local success = require('utils.terminal.manager').switch_terminal()
```

**返回值**：
- `boolean` - 操作是否成功

**行為邏輯**：
- 如果 Claude Code 可見 → 切換到 Gemini
- 如果 Gemini 可見 → 切換到 Claude Code  
- 如果都不可見 → 開啟最後使用的終端（預設 Claude Code）

#### 狀態查詢

##### `get_status()`
獲取終端管理器狀態。

```lua
local status = require('utils.terminal.manager').get_status()
```

**返回值**：
```lua
{
  claude_code = {
    available = boolean,  -- 是否可用
    visible = boolean,    -- 是否可見
    buf = number|nil,     -- Buffer ID
    win = number|nil,     -- Window ID
    is_current = boolean  -- 是否為當前視窗
  },
  gemini = {
    available = boolean,
    visible = boolean,
    buf = number|nil,
    win = number|nil,
    job_id = number|nil   -- Job ID
  },
  last_active = string|nil,  -- 最後活躍的終端名稱
  busy = boolean            -- 是否忙碌中
}
```

##### `get_statistics()`
獲取操作統計資訊。

```lua
local stats = require('utils.terminal.manager').get_statistics()
```

**返回值**：
```lua
{
  total_operations = number,      -- 總操作次數
  successful_operations = number, -- 成功操作次數
  failed_operations = number,     -- 失敗操作次數
  recovery_operations = number,   -- 恢復操作次數
  success_rate = string,         -- 成功率（百分比字串）
  last_health_check = string     -- 最後健康檢查時間
}
```

#### 健康檢查與維護

##### `health_check()`
執行完整健康檢查。

```lua
local report = require('utils.terminal.manager').health_check()
```

**返回值**：
```lua
{
  timestamp = string,           -- 檢查時間
  overall_status = string,      -- 整體狀態
  issues = {string},           -- 問題列表
  modules = {                  -- 模組狀態
    claude = {
      status = string,
      issues = {string}
    },
    gemini = {
      status = string, 
      issues = {string}
    },
    state = {
      status = string,
      issues = {string}
    }
  },
  statistics = table           -- 操作統計
}
```

##### `cleanup()`
清理無效狀態。

```lua
local status = require('utils.terminal.manager').cleanup()
```

##### `reset()`
完全重置終端管理器。

```lua
local status = require('utils.terminal.manager').reset()
```

##### `force_recovery()`
強制錯誤恢復。

```lua
local status = require('utils.terminal.manager').force_recovery()
```

#### 診斷工具

##### `performance_diagnostic()`
執行性能診斷。

```lua
local results = require('utils.terminal.manager').performance_diagnostic()
```

**返回值**：
```lua
{
  switch_time_ms = number,        -- 切換時間（毫秒）
  switch_performance = string,    -- 性能評級
  switch_success = boolean,       -- 切換是否成功
  memory_usage_kb = number,       -- 記憶體使用（KB）
  statistics = table             -- 統計資訊
}
```

##### `debug_info()`
獲取完整除錯資訊。

```lua
local debug_data = require('utils.terminal.manager').debug_info()
```

## 🔌 Terminal Adapters API

### Claude Code Adapter
`require('utils.terminal.adapters.claude')`

#### 核心方法

兩種API風格都支援：

##### 標準 API（推薦）
```lua
-- 開啟終端
local success = require('utils.terminal.adapters.claude').show(options)

-- 關閉終端
local success = require('utils.terminal.adapters.claude').hide()

-- 切換終端
local success = require('utils.terminal.adapters.claude').toggle(options)
```

##### 別名 API（向後相容）
```lua
-- 別名：show() 
local success = require('utils.terminal.adapters.claude').open(options)

-- 別名：hide()
local success = require('utils.terminal.adapters.claude').close()
```

##### 其他核心方法
```lua
-- 檢查是否可見
local visible = require('utils.terminal.adapters.claude').is_visible()

-- 健康檢查
local health_ok, issues = require('utils.terminal.adapters.claude').health_check()
```

#### 特殊方法

##### `find_claude_terminal()`
尋找現有的 Claude Code 終端。

```lua
local terminal_info = require('utils.terminal.adapters.claude').find_claude_terminal()
```

**返回值**：
```lua
{
  buf = number,         -- Buffer ID
  win = number|nil,     -- Window ID（如果可見）
  is_current = boolean  -- 是否為當前視窗
} or nil
```

### Gemini Adapter
`require('utils.terminal.adapters.gemini')`

#### 核心方法

與 Claude Code 適配器提供相同的 API：

##### 標準 API（推薦）
```lua
-- 開啟終端
local success = require('utils.terminal.adapters.gemini').show(options)

-- 關閉終端
local success = require('utils.terminal.adapters.gemini').hide()

-- 切換終端
local success = require('utils.terminal.adapters.gemini').toggle(options)

-- 檢查是否可見
local visible = require('utils.terminal.adapters.gemini').is_visible()

-- 健康檢查
local health_ok, issues = require('utils.terminal.adapters.gemini').health_check()
```

##### 別名 API（向後相容）
```lua
-- 別名：show() 
local success = require('utils.terminal.adapters.gemini').open(options)

-- 別名：hide()
local success = require('utils.terminal.adapters.gemini').close()
```

**註：** 兩個適配器現在提供完全一致的 API 接口。

## 🎯 Unified Terminal API

### `require('utils.terminal.init')`

統一的終端管理 API，提供標準化介面。

#### 核心功能

##### `register_terminal(name, adapter)`
註冊新的終端類型。

```lua
local terminal_api = require('utils.terminal.init')
terminal_api.register_terminal('newtool', require('utils.terminal.adapters.newtool'))
```

##### `open_terminal(name, config)`
```lua
local success = terminal_api.open_terminal('claude', {
  ui_config = { width = 0.8 }
})
```

##### `close_terminal(name)`
```lua
local success = terminal_api.close_terminal('claude')
```

##### `toggle_terminal(name, config)`
```lua
local success = terminal_api.toggle_terminal('gemini')
```

#### 批次操作

##### `close_all_terminals()`
```lua
local results = terminal_api.close_all_terminals()
-- 返回：{ claude = true, gemini = true }
```

##### `get_all_terminal_status()`
```lua
local status = terminal_api.get_all_terminal_status()
```

#### 系統功能

##### `health_check()`
```lua
local health_ok, issues, stats = terminal_api.health_check()
```

**返回值**：
- `boolean` - 整體健康狀況
- `{string}` - 問題列表
- `table` - 健康統計

##### `get_system_info()`
```lua
local info = terminal_api.get_system_info()
```

**返回值**：
```lua
{
  version = string,                    -- API 版本
  module_info = table,                -- 模組資訊
  registered_terminals = {string},    -- 已註冊終端列表
  core_modules = {                    -- 核心模組狀態
    core = boolean,
    security = boolean,
    ui = boolean,
    state = boolean
  },
  health_status = {                   -- 健康狀態
    status = string,
    score = number,
    issues_count = number,
    total_checks = number,
    passed_checks = number
  }
}
```

## 📊 State Management API

### `require('utils.terminal.state')`

#### 狀態操作

##### `get_terminal_state(name)`
```lua
local state = require('utils.terminal.state').get_terminal_state('claude')
```

**返回值**：
```lua
{
  buf = number|nil,
  win = number|nil,
  job_id = number|nil,
  created_at = number|nil,
  last_active = number|nil
} or nil
```

##### `set_terminal_state(name, state)`
```lua
local success = require('utils.terminal.state').set_terminal_state('claude', {
  buf = 123,
  win = 456,
  job_id = 789
})
```

##### `remove_terminal_state(name)`
```lua
local success = require('utils.terminal.state').remove_terminal_state('claude')
```

#### 狀態驗證

##### `is_buf_valid(buf)`
```lua
local valid = require('utils.terminal.state').is_buf_valid(buf_id)
```

##### `is_win_valid(win)`
```lua
local valid = require('utils.terminal.state').is_win_valid(win_id)
```

##### `validate_state_isolation()`
檢查終端狀態隔離。

```lua
local valid, message = require('utils.terminal.state').validate_state_isolation()
```

#### 併發控制

##### `set_busy(busy)`
```lua
require('utils.terminal.state').set_busy(true)  -- 設為忙碌
require('utils.terminal.state').set_busy(false) -- 解除忙碌
```

##### `is_busy()`
```lua
local busy = require('utils.terminal.state').is_busy()
```

## 📋 Clipboard API

### `require('utils.clipboard')`

**架構說明**：剪貼板模組採用模組化設計，主入口(`utils.clipboard`)提供統一的公共API，實際功能分散在以下子模組：
- `utils.clipboard.core` - 核心邏輯
- `utils.clipboard.config` - 配置管理  
- `utils.clipboard.security` - 安全檢測
- `utils.clipboard.transport` - 傳輸管理
- `utils.clipboard.state` - 狀態管理

#### 主要功能

##### `copy_with_path()`
標準複製功能（完整內容）。

```lua
require('utils.clipboard').copy_with_path()
```

##### `copy_file_reference(detailed)`
檔案引用複製（節省token）。

```lua
-- 簡潔版本：filename.lua:10-25
require('utils.clipboard').copy_file_reference(false)

-- 詳細版本：包含工作目錄等上下文
require('utils.clipboard').copy_file_reference(true)
```

##### `copy_compressed()`
壓縮格式複製（無元數據）。

```lua
require('utils.clipboard').copy_compressed()
```

##### `copy_next_segment()`
分段複製（處理超長內容）。

```lua
require('utils.clipboard').copy_next_segment()
```

##### `send_to_claude()`
發送到Claude Code。

```lua
require('utils.clipboard').send_to_claude()
```

#### 高級功能

##### `copy_to_file_only()`
僅存檔案（不複製到剪貼板）。

```lua
require('utils.clipboard').copy_to_file_only()
```

##### `diagnose_clipboard()`
診斷剪貼板功能。

```lua
require('utils.clipboard').diagnose_clipboard()
```

##### `configure(new_config)`
配置管理。

```lua
require('utils.clipboard').configure({
  enable_osc52 = true,
  security_check = true,
  performance_monitoring = true
})
```

##### `show_config()`
顯示當前配置。

```lua
require('utils.clipboard').show_config()
```

## 📈 Performance Monitor API

### `require('utils.performance-monitor')`

#### 監控控制

##### `init_startup_tracking()`
初始化啟動追蹤。

```lua
require('utils.performance-monitor').init_startup_tracking()
```

##### `milestone(name)`
記錄啟動里程碑。

```lua
require('utils.performance-monitor').milestone('plugins_loaded')
```

##### `finalize_startup_tracking()`
完成啟動追蹤。

```lua
local startup_time = require('utils.performance-monitor').finalize_startup_tracking()
```

#### 性能測量

##### `benchmark_operation(name, func)`
基準測試操作。

```lua
local result = require('utils.performance-monitor').benchmark_operation('file_operation', function()
  -- 要測量的操作
  return some_operation()
end)
```

##### `get_memory_usage()`
獲取記憶體使用情況。

```lua
local memory = require('utils.performance-monitor').get_memory_usage()
```

**返回值**：
```lua
{
  rss_bytes = number,   -- 常駐記憶體（位元組）
  rss_kb = number,      -- 常駐記憶體（KB）
  rss_mb = number,      -- 常駐記憶體（MB）
  buffers = number,     -- Buffer 數量
  windows = number,     -- 視窗數量
  tabpages = number,    -- Tab 頁數量
  timestamp = number    -- 時間戳
}
```

#### 報告生成

##### `get_performance_stats()`
獲取性能統計。

```lua
local stats = require('utils.performance-monitor').get_performance_stats()
```

##### `generate_performance_report()`
生成性能報告。

```lua
local report = require('utils.performance-monitor').generate_performance_report()
print(report)
```

##### `show_status()`
顯示即時狀態。

```lua
require('utils.performance-monitor').show_status()
```

##### `show_report()`
顯示詳細報告。

```lua
require('utils.performance-monitor').show_report()
```

##### `run_benchmarks()`
執行基準測試。

```lua
require('utils.performance-monitor').run_benchmarks()
```

#### 配置管理

##### `update_config(new_config)`
更新監控配置。

```lua
require('utils.performance-monitor').update_config({
  thresholds = {
    startup_time_ms = 1000
  }
})
```

##### `toggle_monitoring()`
切換監控開關。

```lua
require('utils.performance-monitor').toggle_monitoring()
```

## ❌ Error Handler API

### `require('utils.error-handler')`

#### 錯誤處理

##### `handle_error(error_msg, context)`
處理錯誤。

```lua
require('utils.error-handler').handle_error('操作失敗', {
  operation = 'terminal_open',
  terminal = 'claude'
})
```

##### `safe_execute(func, error_context)`
安全執行函數。

```lua
local success, result = require('utils.error-handler').safe_execute(function()
  return risky_operation()
end, { operation = 'test' })
```

## 🔧 使用範例

### 完整工作流程範例

```lua
-- 1. 檢查系統健康
local manager = require('utils.terminal.manager')
local health_report = manager.health_check()

if health_report.overall_status ~= '健康' then
  print('⚠️ 發現問題，嘗試清理...')
  manager.cleanup()
end

-- 2. 開啟 Claude Code
local success = manager.toggle_claude_code()
if success then
  print('✅ Claude Code 已開啟')
  
  -- 3. 等待一會兒後切換到 Gemini
  vim.defer_fn(function()
    manager.switch_terminal()
    print('🔄 已切換到 Gemini')
  end, 2000)
end

-- 4. 監控性能
local perf_monitor = require('utils.performance-monitor')
perf_monitor.benchmark_operation('terminal_switch', function()
  manager.switch_terminal()
end)

-- 5. 獲取統計
local stats = manager.get_statistics()
print(string.format('成功率: %s', stats.success_rate))
```

### 自定義終端適配器範例

```lua
-- 使用統一 API 註冊自定義終端
local terminal_api = require('utils.terminal.init')
local my_adapter = require('utils.terminal.adapters.mytool')

-- 註冊
terminal_api.register_terminal('mytool', my_adapter)

-- 使用
terminal_api.toggle_terminal('mytool', {
  ui_config = { width = 0.9 }
})

-- 檢查狀態
local status = terminal_api.get_terminal_status('mytool')
print('MyTool 可見:', status.visible)
```

---

這個 API 文檔涵蓋了系統的所有公開介面。如需更多範例或有疑問，請參考相應的模組源碼或聯繫維護者。