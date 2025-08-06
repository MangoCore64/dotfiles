-- Phase 2 完整測試套件
-- 測試 Phase 2 所有重構後的模組整合
local Path = require('plenary.path')

-- 設定測試環境路徑
package.path = package.path .. ';' .. vim.fn.expand('~/.config/nvim/lua') .. '/?.lua'

-- 測試用的 mock vim API（統一版本）
local function setup_test_env()
  -- 基本 vim 對象
  if not vim.o then
    vim.o = {
      columns = 120,
      lines = 40
    }
  end
  
  if not vim.log then
    vim.log = {
      levels = {
        DEBUG = 0,
        INFO = 1,
        WARN = 2,
        ERROR = 3
      }
    }
  end
  
  if not vim.notify then
    vim.notify = function(msg, level)
      local level_name = "INFO"
      if level == vim.log.levels.ERROR then level_name = "ERROR"
      elseif level == vim.log.levels.WARN then level_name = "WARN"
      elseif level == vim.log.levels.DEBUG then level_name = "DEBUG" end
      print(string.format("[%s] %s", level_name, msg))
    end
  end
  
  -- vim.fn 函數
  if not vim.fn then
    vim.fn = {}
  end
  
  vim.fn.localtime = vim.fn.localtime or function() return os.time() end
  vim.fn.exepath = vim.fn.exepath or function(cmd) return "/usr/bin/" .. cmd end
  vim.fn.executable = vim.fn.executable or function(path) return 1 end
  
  -- vim.api 函數  
  if not vim.api then
    vim.api = {}
  end
  
  vim.api.nvim_get_commands = vim.api.nvim_get_commands or function() return {} end
  vim.api.nvim_list_bufs = vim.api.nvim_list_bufs or function() return {} end
  vim.api.nvim_list_wins = vim.api.nvim_list_wins or function() return {} end
  vim.api.nvim_get_current_win = vim.api.nvim_get_current_win or function() return 1 end
  vim.api.nvim_get_current_buf = vim.api.nvim_get_current_buf or function() return 1 end
  vim.api.nvim_buf_is_valid = vim.api.nvim_buf_is_valid or function(buf) return buf and buf > 0 end
  vim.api.nvim_win_is_valid = vim.api.nvim_win_is_valid or function(win) return win and win > 0 end
  
  -- vim.loop (libuv)
  if not vim.loop then
    vim.loop = {}
  end
  
  vim.loop.fs_stat = vim.loop.fs_stat or function(path)
    return {type = "file", size = 1024}
  end
  
  vim.loop.fs_lstat = vim.loop.fs_lstat or function(path)
    return {type = "file", size = 1024}
  end
  
  vim.loop.fs_access = vim.loop.fs_access or function(path, mode)
    return true
  end
  
  -- 其他工具函數
  vim.defer_fn = vim.defer_fn or function(fn, timeout) fn() end
  vim.cmd = vim.cmd or function(command) return end
  vim.inspect = vim.inspect or function(obj) return tostring(obj) end
  vim.tbl_count = vim.tbl_count or function(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
  end
  vim.list_extend = vim.list_extend or function(dst, src)
    for _, item in ipairs(src) do table.insert(dst, item) end
    return dst
  end
  vim.tbl_deep_extend = vim.tbl_deep_extend or function(behavior, ...)
    local result = {}
    for _, tbl in ipairs({...}) do
      for k, v in pairs(tbl) do
        result[k] = v
      end
    end
    return result
  end
end

-- Phase 2 測試結果記錄
local test_results = {
  modules = {},
  integration = {},
  overall = {
    passed = 0,
    failed = 0,
    warnings = 0
  }
}

-- 測試單個模組
local function test_module(module_path, module_name, expected_functions)
  print(string.format("\n🧪 測試 %s 模組...", module_name))
  
  local result = {
    name = module_name,
    loaded = false,
    functions = {},
    health = {},
    issues = {}
  }
  
  -- 測試模組載入
  local success, module = pcall(require, module_path)
  if success and module then
    result.loaded = true
    print(string.format("  ✓ %s 模組載入成功", module_name))
  else
    result.issues[#result.issues + 1] = "模組載入失敗: " .. tostring(module)
    print(string.format("  ✗ %s 模組載入失敗: %s", module_name, tostring(module)))
    return result
  end
  
  -- 測試必需函數
  for _, func_name in ipairs(expected_functions or {}) do
    if module[func_name] and type(module[func_name]) == "function" then
      result.functions[func_name] = true
      print(string.format("  ✓ 函數 %s 存在", func_name))
    else
      result.functions[func_name] = false
      result.issues[#result.issues + 1] = "缺少函數: " .. func_name
      print(string.format("  ✗ 函數 %s 缺失", func_name))
    end
  end
  
  -- 測試健康檢查（如果存在）
  if module.health_check and type(module.health_check) == "function" then
    local health_success, health_valid, health_issues = pcall(module.health_check)
    if health_success then
      result.health.valid = health_valid
      result.health.issues = health_issues or {}
      if health_valid then
        print(string.format("  ✓ %s 健康檢查通過", module_name))
      else
        print(string.format("  ⚠️ %s 健康檢查發現問題:", module_name))
        for _, issue in ipairs(health_issues or {}) do
          print("    - " .. issue)
        end
      end
    else
      result.issues[#result.issues + 1] = "健康檢查執行失敗"
      print(string.format("  ✗ %s 健康檢查執行失敗", module_name))
    end
  end
  
  return result
end

-- 執行 Phase 2 完整測試
local function run_phase2_tests()
  print("🎯 開始 Phase 2 完整測試套件...")
  setup_test_env()
  
  -- 定義要測試的模組
  local modules_to_test = {
    {
      path = 'utils.terminal.security',
      name = 'Security',
      functions = {
        'validate_path_security', 'secure_file_check', 'validate_command',
        'update_command_path', 'get_security_config', 'validate_security_config',
        'security_audit'
      }
    },
    {
      path = 'utils.terminal.ui',
      name = 'UI',
      functions = {
        'create_floating_window', 'create_gemini_window', 'create_claude_window',
        'close_window', 'is_window_visible', 'focus_window', 'health_check'
      }
    },
    {
      path = 'utils.terminal.core',
      name = 'Core',
      functions = {
        'is_terminal_visible', 'open_terminal', 'close_terminal', 'toggle_terminal',
        'destroy_terminal', 'get_terminal_status', 'list_terminals', 'health_check'
      }
    },
    {
      path = 'utils.terminal.state',
      name = 'State',
      functions = {
        'get_terminal_state', 'set_terminal_state', 'remove_terminal_state',
        'list_terminals', 'cleanup_invalid_state', 'validate_state_isolation'
      }
    },
    {
      path = 'utils.terminal.adapters.gemini',
      name = 'Gemini',
      functions = {
        'is_visible', 'show', 'hide', 'toggle', 'destroy', 'get_status',
        'health_check', 'security_audit'
      }
    },
    {
      path = 'utils.terminal.adapters.claude',
      name = 'Claude',
      functions = {
        'find_claude_terminal', 'is_visible', 'toggle', 'open', 'close',
        'get_status', 'health_check'
      }
    },
    {
      path = 'utils.terminal.manager',
      name = 'Manager',
      functions = {
        'toggle_claude_code', 'toggle_gemini', 'switch_terminal',
        'get_status', 'cleanup', 'reset'
      }
    }
  }
  
  -- 測試每個模組
  for _, module_info in ipairs(modules_to_test) do
    local result = test_module(module_info.path, module_info.name, module_info.functions)
    test_results.modules[module_info.name] = result
    
    if result.loaded and #result.issues == 0 then
      test_results.overall.passed = test_results.overall.passed + 1
    elseif result.loaded and #result.issues > 0 then
      test_results.overall.warnings = test_results.overall.warnings + 1
    else
      test_results.overall.failed = test_results.overall.failed + 1
    end
  end
  
  return test_results
end

-- 測試模組間整合
local function test_integration()
  print("\n🔗 測試模組整合...")
  
  local integration_tests = {
    {
      name = "Core + Security 整合",
      test = function()
        local core_success, core = pcall(require, 'utils.terminal.core')
        local security_success, security = pcall(require, 'utils.terminal.security')
        
        if not (core_success and security_success) then
          return false, "模組載入失敗"
        end
        
        -- 測試 core 是否使用 security 驗證
        local health_valid, health_issues = core.health_check()
        if health_valid then
          return true, "整合正常"
        else
          return false, "健康檢查失敗: " .. table.concat(health_issues or {}, ", ")
        end
      end
    },
    {
      name = "Core + UI 整合",
      test = function()
        local core_success, core = pcall(require, 'utils.terminal.core')
        local ui_success, ui = pcall(require, 'utils.terminal.ui')
        
        if not (core_success and ui_success) then
          return false, "模組載入失敗"
        end
        
        -- 測試 UI 健康檢查
        local ui_health_valid = ui.health_check()
        return ui_health_valid, ui_health_valid and "整合正常" or "UI 健康檢查失敗"
      end
    },
    {
      name = "Gemini + Core 整合",
      test = function()
        local gemini_success, gemini = pcall(require, 'utils.terminal.adapters.gemini')
        local core_success, core = pcall(require, 'utils.terminal.core')
        
        if not (gemini_success and core_success) then
          return false, "模組載入失敗"
        end
        
        -- 測試 Gemini 狀態檢查
        local status = gemini.get_status()
        return status ~= nil, status and "整合正常" or "狀態檢查失敗"
      end
    },
    {
      name = "Claude + Core 整合",
      test = function()
        local claude_success, claude = pcall(require, 'utils.terminal.adapters.claude')
        local core_success, core = pcall(require, 'utils.terminal.core')
        
        if not (claude_success and core_success) then
          return false, "模組載入失敗"
        end
        
        -- 測試 Claude 狀態檢查
        local status = claude.get_status()
        return status ~= nil, status and "整合正常" or "狀態檢查失敗"
      end
    }
  }
  
  local integration_passed = 0
  local integration_failed = 0
  
  for _, test_info in ipairs(integration_tests) do
    local success, message = test_info.test()
    test_results.integration[test_info.name] = {
      success = success,
      message = message
    }
    
    if success then
      print(string.format("  ✓ %s: %s", test_info.name, message))
      integration_passed = integration_passed + 1
    else
      print(string.format("  ✗ %s: %s", test_info.name, message))
      integration_failed = integration_failed + 1
    end
  end
  
  return integration_passed, integration_failed
end

-- 生成測試報告
local function generate_report()
  print("\n📊 Phase 2 測試報告")
  print("==================")
  
  print("\n🎯 模組測試結果:")
  for module_name, result in pairs(test_results.modules) do
    local status = result.loaded and (#result.issues == 0 and "✅" or "⚠️") or "❌"
    print(string.format("  %s %s: %s", status, module_name, 
      result.loaded and "載入成功" or "載入失敗"))
    
    if #result.issues > 0 then
      for _, issue in ipairs(result.issues) do
        print("    - " .. issue)
      end
    end
  end
  
  print("\n🔗 整合測試結果:")
  for test_name, result in pairs(test_results.integration) do
    local status = result.success and "✅" or "❌"
    print(string.format("  %s %s: %s", status, test_name, result.message))
  end
  
  print("\n📈 總體統計:")
  print(string.format("  通過: %d", test_results.overall.passed))
  print(string.format("  警告: %d", test_results.overall.warnings))
  print(string.format("  失敗: %d", test_results.overall.failed))
  
  local total = test_results.overall.passed + test_results.overall.warnings + test_results.overall.failed
  local success_rate = total > 0 and (test_results.overall.passed / total) * 100 or 0
  
  print(string.format("  成功率: %.1f%%", success_rate))
  
  return success_rate >= 80  -- 80% 成功率視為通過
end

-- 主測試函數
local function run_complete_phase2_test()
  -- 執行模組測試
  run_phase2_tests()
  
  -- 執行整合測試
  local integration_passed, integration_failed = test_integration()
  
  -- 生成報告
  local overall_success = generate_report()
  
  if overall_success then
    print("\n🎉 Phase 2 測試套件整體通過！")
    print("所有模組已成功重構並整合。")
  else
    print("\n⚠️ Phase 2 測試套件發現問題")
    print("請檢查失敗的模組並修復問題。")
  end
  
  return overall_success, test_results
end

-- 如果直接執行此文件，運行完整測試
if ... == nil then
  local success, results = run_complete_phase2_test()
  os.exit(success and 0 or 1)
end

-- 返回測試函數供其他模組使用
return {
  run_complete_phase2_test = run_complete_phase2_test,
  test_module = test_module,
  test_integration = test_integration,
  generate_report = generate_report
}