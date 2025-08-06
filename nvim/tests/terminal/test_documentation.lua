-- 文檔完整性和一致性測試
-- 確保文檔涵蓋所有 API 並且範例代碼可執行

print("📚 文檔完整性測試")
print("=" .. string.rep("=", 50))

-- 測試結果統計
local test_results = {
  total_tests = 0,
  passed_tests = 0,
  failed_tests = 0,
  test_details = {}
}

-- 測試工具函數
local function test_assert(condition, test_name, error_msg)
  test_results.total_tests = test_results.total_tests + 1
  
  if condition then
    test_results.passed_tests = test_results.passed_tests + 1
    table.insert(test_results.test_details, {
      name = test_name,
      status = "✅ 通過",
      message = ""
    })
    print(string.format("  ✅ %s", test_name))
  else
    test_results.failed_tests = test_results.failed_tests + 1
    table.insert(test_results.test_details, {
      name = test_name,
      status = "❌ 失敗",
      message = error_msg or "測試失敗"
    })
    print(string.format("  ❌ %s: %s", test_name, error_msg or "測試失敗"))
  end
end

-- 檢查文檔文件是否存在
print("\n1. 📁 文檔文件存在性檢查")

local doc_files = {
  "docs/ARCHITECTURE.md",
  "docs/TERMINAL_ARCHITECTURE.md", 
  "docs/USER_GUIDE.md",
  "docs/QUICKSTART.md",
  "docs/TROUBLESHOOTING.md",
  "docs/EXTENDING.md",
  "docs/API_REFERENCE.md"
}

for _, file_path in ipairs(doc_files) do
  local file = io.open(file_path, "r")
  test_assert(
    file ~= nil,
    string.format("文檔文件存在: %s", file_path),
    "文檔文件不存在"
  )
  if file then
    file:close()
  end
end

-- 檢查模組 API 覆蓋率
print("\n2. 📋 API 覆蓋率檢查")

-- 定義需要文檔化的模組和其主要 API
local api_modules = {
  ['utils.terminal.manager'] = {
    'toggle_claude_code',
    'toggle_gemini', 
    'switch_terminal',
    'get_status',
    'health_check',
    'cleanup',
    'reset'
  },
  ['utils.terminal.adapters.claude'] = {
    'open',
    'close',
    'toggle',
    'is_visible',
    'health_check'
  },
  ['utils.terminal.adapters.gemini'] = {
    'open',
    'close', 
    'toggle',
    'show',
    'hide',
    'is_visible',
    'health_check'
  },
  ['utils.terminal.init'] = {
    'register_terminal',
    'open_terminal',
    'close_terminal',
    'toggle_terminal',
    'health_check',
    'get_system_info'
  },
  ['utils.terminal.state'] = {
    'get_terminal_state',
    'set_terminal_state',
    'is_buf_valid',
    'is_win_valid',
    'set_busy',
    'is_busy'
  },
  ['utils.clipboard'] = {
    'get_visual_selection',
    'copy_with_security_filter',
    'create_file_reference'
  },
  ['utils.performance-monitor'] = {
    'init_startup_tracking',
    'benchmark_operation',
    'get_memory_usage',
    'show_status',
    'show_report'
  }
}

-- 讀取 API 參考文檔
local api_doc_file = io.open("docs/API_REFERENCE.md", "r")
local api_doc_content = ""
if api_doc_file then
  api_doc_content = api_doc_file:read("*all")
  api_doc_file:close()
end

-- 檢查每個模組的 API 是否在文檔中
for module_name, apis in pairs(api_modules) do
  for _, api_name in ipairs(apis) do
    local pattern = api_name:gsub("([%[%]%(%)%*%+%-%?%^%$%.])", "%%%1")
    local found = api_doc_content:find(pattern, 1, false)
    
    test_assert(
      found ~= nil,
      string.format("API 文檔化: %s.%s", module_name, api_name),
      string.format("API %s 未在文檔中找到", api_name)
    )
  end
end

-- 檢查文檔中的代碼範例是否可執行
print("\n3. 🧪 代碼範例可執行性檢查")

-- 測試一些關鍵的 API 調用是否有效
local function test_api_availability()
  -- 測試模組可載入性
  local modules_to_test = {
    'utils.terminal.manager',
    'utils.terminal.adapters.claude',
    'utils.terminal.adapters.gemini',
    'utils.terminal.init',
    'utils.terminal.state',
    'utils.clipboard',
    'utils.performance-monitor'
  }
  
  for _, module_name in ipairs(modules_to_test) do
    local success, module = pcall(require, module_name)
    test_assert(
      success,
      string.format("模組可載入: %s", module_name),
      string.format("模組載入失敗: %s", module or "unknown error")
    )
    
    if success and module then
      -- 檢查模組是否有預期的函數
      local expected_functions = api_modules[module_name] or {}
      for _, func_name in ipairs(expected_functions) do
        test_assert(
          type(module[func_name]) == "function",
          string.format("函數存在: %s.%s", module_name, func_name),
          string.format("函數不存在或不是函數類型")
        )
      end
    end
  end
end

test_api_availability()

-- 測試文檔中的關鍵範例
print("\n4. 📖 文檔範例測試")

-- 測試 terminal.manager 基本操作
local function test_terminal_manager_examples()
  local manager = require('utils.terminal.manager')
  
  -- 測試狀態查詢（文檔中的範例）
  local status = manager.get_status()
  test_assert(
    type(status) == "table",
    "get_status() 返回 table",
    "get_status() 未返回預期的 table 類型"
  )
  
  test_assert(
    status.claude_code ~= nil and status.gemini ~= nil,
    "狀態包含必要字段",
    "狀態結構不完整"
  )
  
  -- 測試統計資訊（文檔中的範例）
  local stats = manager.get_statistics()
  test_assert(
    type(stats) == "table" and stats.success_rate ~= nil,
    "get_statistics() 返回統計資訊",
    "統計資訊結構不正確"
  )
end

pcall(test_terminal_manager_examples)

-- 測試 clipboard API
local function test_clipboard_examples()
  local clipboard = require('utils.clipboard')
  
  -- 測試安全過濾函數（文檔中的範例）
  local test_content = "這是測試內容"
  local filtered = clipboard.copy_with_security_filter(test_content)
  test_assert(
    type(filtered) == "string",
    "copy_with_security_filter() 正常工作",
    "安全過濾函數返回類型錯誤"
  )
end

pcall(test_clipboard_examples)

-- 測試性能監控 API
local function test_performance_monitor_examples()
  local perf_monitor = require('utils.performance-monitor')
  
  -- 測試記憶體使用獲取（文檔中的範例）
  local memory_info = perf_monitor.get_memory_usage()
  test_assert(
    type(memory_info) == "table" and memory_info.rss_mb ~= nil,
    "get_memory_usage() 返回記憶體資訊",
    "記憶體資訊結構不正確"
  )
end

pcall(test_performance_monitor_examples)

-- 檢查文檔的交叉引用
print("\n5. 🔗 文檔交叉引用檢查")

local function check_cross_references()
  -- 檢查文檔間的引用是否有效
  local user_guide_file = io.open("docs/USER_GUIDE.md", "r")
  if user_guide_file then
    local content = user_guide_file:read("*all")
    user_guide_file:close()
    
    -- 檢查是否引用了其他文檔
    local has_quickstart_ref = content:find("QUICKSTART", 1, true)
    local has_troubleshooting_ref = content:find("TROUBLESHOOTING", 1, true)
    
    test_assert(
      has_quickstart_ref or has_troubleshooting_ref,
      "USER_GUIDE 有交叉引用",
      "USER_GUIDE 缺少交叉引用"
    )
  end
end

check_cross_references()

-- 檢查快捷鍵一致性
print("\n6. ⌨️ 快捷鍵一致性檢查")

local function check_keybinding_consistency()
  -- 檢查文檔中記錄的快捷鍵與實際配置是否一致
  local function read_file(path)
    local file = io.open(path, "r")
    if file then
      local content = file:read("*all")
      file:close()
      return content
    end
    return nil
  end
  
  local mappings_content = read_file("/home/mangowang/.config/nvim/lua/mappings.lua")
  local plugins_content = read_file("/home/mangowang/.config/nvim/lua/plugins/init.lua")
  
  if not mappings_content and not plugins_content then
    test_assert(false, "快捷鍵配置文件存在", "無法讀取快捷鍵配置文件")
    return
  end
  
  -- 檢查關鍵快捷鍵是否存在（指定查找位置）
  local key_configs = {
    {key = "<leader>cc", desc = "Claude Code", content = plugins_content},
    {key = "<leader>gm", desc = "Gemini", content = plugins_content},
    {key = "<leader>tt", desc = "Terminal toggle", content = plugins_content},
    {key = "<leader>cs", desc = "Send to Claude", content = mappings_content}
  }
  
  for _, config in ipairs(key_configs) do
    local found = false
    local escaped_pattern = config.key:gsub("([<>])", "%%%1")
    
    if config.content and config.content:find(escaped_pattern, 1, true) then
      found = true
    end
    
    test_assert(
      found,
      string.format("快捷鍵配置存在: %s", config.key),
      string.format("快捷鍵 %s (%s) 未在配置文件中找到", config.key, config.desc)
    )
  end
end

check_keybinding_consistency()

-- 檢查 CLAUDE.md 更新
print("\n7. 📝 專案文檔更新檢查")

local function check_project_docs()
  local claude_md_file = io.open("CLAUDE.md", "r")
  if claude_md_file then
    local content = claude_md_file:read("*all")
    claude_md_file:close()
    
    -- 檢查是否包含終端管理系統的描述
    local has_terminal_mention = content:find("terminal", 1, true) or content:find("Terminal", 1, true)
    test_assert(
      has_terminal_mention,
      "CLAUDE.md 包含終端管理系統描述",
      "CLAUDE.md 可能需要更新以包含新功能"
    )
  end
end

check_project_docs()

-- 結果統計
print(string.rep("=", 50))
print("📊 文檔測試結果統計")
print(string.rep("=", 50))

local success_rate = test_results.total_tests > 0 and 
  (test_results.passed_tests / test_results.total_tests * 100) or 0

print(string.format("總測試數: %d", test_results.total_tests))
print(string.format("通過測試: %d", test_results.passed_tests))
print(string.format("失敗測試: %d", test_results.failed_tests))
print(string.format("成功率: %.1f%%", success_rate))

-- 整體判定
if test_results.failed_tests == 0 then
  print("\n🎉 所有文檔測試通過！")
  print("✅ 文檔完整性良好")
  print("✅ API 覆蓋率充足")
  print("✅ 代碼範例可執行")
  print("✅ 交叉引用正確")
else
  print("\n⚠️ 部分文檔測試失敗")
  print("需要檢查以下問題：")
  
  for _, test_detail in ipairs(test_results.test_details) do
    if test_detail.status:find("❌") then
      print(string.format("  • %s: %s", test_detail.name, test_detail.message))
    end
  end
end

-- 建議
print("\n💡 文檔改進建議:")
if success_rate >= 95 then
  print("  • 文檔品質優秀，建議定期維護更新")
  print("  • 可考慮添加更多使用場景範例")
elseif success_rate >= 80 then
  print("  • 文檔品質良好，建議修復失敗的測試項目")
  print("  • 加強 API 覆蓋率")
else
  print("  • 需要大幅改進文檔完整性")
  print("  • 建議重新審查文檔結構")
end

-- 返回結果供進一步分析
return {
  success = test_results.failed_tests == 0,
  success_rate = success_rate,
  total_tests = test_results.total_tests,
  passed_tests = test_results.passed_tests,
  failed_tests = test_results.failed_tests,
  test_details = test_results.test_details
}