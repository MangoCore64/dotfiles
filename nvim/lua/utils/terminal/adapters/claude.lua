-- 🔒 Claude Code Terminal Adapter - 輕量安全版本
-- 專注於 Claude Code 特定功能的輕量適配器
-- 
-- 特色：
-- - 輕量化設計 (~95行)
-- - 保留關鍵安全機制
-- - 委託核心功能給 core.lua
-- - 向後相容 API

local M = {}
local core = require('utils.terminal.core')
local security = require('utils.terminal.security')

-- Claude Code 終端配置
local CLAUDE_CONFIG = {
  name = "claude_code",
  command = "claude",
  title = "Claude Code Terminal", 
  security_level = "high",
  ui_config = {
    width_ratio = 0.9,
    height_ratio = 0.9,
    border = "double"
  }
}

-- 基礎終端操作 (委託給 core.lua)
function M.open()
  local success, result = pcall(core.open_terminal, CLAUDE_CONFIG)
  if not success then
    vim.notify("❌ 開啟 Claude Code 終端失敗: " .. tostring(result), vim.log.levels.ERROR)
    return false
  end
  return result
end

function M.show()
  -- 向後相容別名
  return M.open()
end

function M.close()
  return core.close_terminal("claude_code")
end

function M.hide()
  -- 向後相容別名
  return M.close()
end

function M.toggle()
  return core.toggle_terminal("claude_code", CLAUDE_CONFIG)
end

function M.is_visible()
  return core.is_terminal_visible("claude_code")
end

function M.get_status()
  return core.get_terminal_status("claude_code")
end

-- 🔒 關鍵安全函數 (必須保留)
function M.security_audit()
  return security.security_audit()
end

function M.security_test()
  -- 簡化版但保留核心檢查
  vim.notify("🧪 開始 Claude Code 終端安全測試...", vim.log.levels.INFO)
  
  local tests_passed = 0
  local tests_failed = 0
  local issues = {}
  
  -- 測試 1: Claude 命令可用性
  local claude_valid, claude_path, claude_error = security.validate_command("claude")
  if claude_valid then
    vim.notify("✅ Claude 命令驗證通過: " .. claude_path, vim.log.levels.INFO)
    tests_passed = tests_passed + 1
  else
    local error_msg = "Claude 命令驗證失敗: " .. tostring(claude_error)
    table.insert(issues, error_msg)
    vim.notify("❌ " .. error_msg, vim.log.levels.ERROR)
    tests_failed = tests_failed + 1
  end
  
  -- 測試 2: 核心模組健康檢查
  local core_valid, core_issues = core.health_check()
  if core_valid then
    vim.notify("✅ 核心模組健康檢查通過", vim.log.levels.INFO)
    tests_passed = tests_passed + 1
  else
    vim.notify("❌ 核心模組健康檢查失敗", vim.log.levels.ERROR)
    vim.list_extend(issues, core_issues or {})
    tests_failed = tests_failed + 1
  end
  
  -- 測試 3: 安全配置檢查
  local security_valid, security_issues = security.validate_security_config()
  if security_valid then
    vim.notify("✅ 安全配置檢查通過", vim.log.levels.INFO)
    tests_passed = tests_passed + 1
  else
    vim.notify("❌ 安全配置檢查失敗", vim.log.levels.ERROR)
    vim.list_extend(issues, security_issues or {})
    tests_failed = tests_failed + 1
  end
  
  -- 測試總結
  local total_tests = tests_passed + tests_failed
  local success = tests_passed == total_tests
  vim.notify(string.format("🧪 Claude 安全測試完成: %d/%d 通過", tests_passed, total_tests), 
    success and vim.log.levels.INFO or vim.log.levels.WARN)
  
  return success, issues
end

function M.show_config()
  local security_config = security.get_security_config()
  local claude_status = M.get_status()
  
  -- 簡化版配置顯示，保留安全檢查
  local config_info = "=== 🔧 Claude Code 安全配置 ===\n"
  
  -- 顯示 Claude 命令路徑
  local claude_path = security_config.secure_commands and security_config.secure_commands.claude or "未配置"
  config_info = config_info .. string.format("Claude 路徑: %s\n", claude_path)
  
  -- 顯示終端狀態
  config_info = config_info .. string.format("終端狀態: %s\n", claude_status.visible and "可見" or "隱藏")
  config_info = config_info .. string.format("存在: %s\n", claude_status.exists and "是" or "否")
  
  if claude_status.created_at then
    config_info = config_info .. string.format("創建時間: %s\n", 
      os.date("%Y-%m-%d %H:%M:%S", claude_status.created_at))
  end
  
  vim.notify(config_info, vim.log.levels.INFO)
  return config_info
end

function M.update_command_path(cmd_name, new_path)
  if not cmd_name or not new_path then
    vim.notify("❌ 無效的命令或路徑參數", vim.log.levels.ERROR)
    return false
  end
  return security.update_command_path(cmd_name, new_path)
end

function M.health_check()
  -- 委託給核心但添加 Claude 特定檢查
  local core_valid, core_issues = core.health_check()
  local issues = core_issues or {}
  
  -- Claude 特定檢查
  if not CLAUDE_CONFIG.name or not CLAUDE_CONFIG.command then
    table.insert(issues, "Claude 配置不完整")
  end
  
  -- 檢查 Claude 命令可用性
  local claude_valid, _, claude_error = security.validate_command("claude")
  if not claude_valid then
    table.insert(issues, "Claude 命令不可用: " .. tostring(claude_error))
  end
  
  return #issues == 0, issues
end

-- 🔧 向後相容功能 (簡化版)
function M.destroy()
  return core.destroy_terminal("claude_code")
end

function M.restart()
  vim.notify("🔄 重啟 Claude Code 終端...", vim.log.levels.INFO)
  
  local destroy_success = M.destroy()
  if not destroy_success then
    vim.notify("⚠️ 無法銷毀現有終端", vim.log.levels.WARN)
  end
  
  vim.defer_fn(function()
    local open_success = M.open()
    if open_success then
      vim.notify("✅ Claude Code 終端重啟成功", vim.log.levels.INFO)
    else
      vim.notify("❌ Claude Code 終端重啟失敗", vim.log.levels.ERROR)
    end
  end, 100)
  
  return true
end

-- 簡化的終端查找 (向後相容)
function M.find_claude_terminal()
  local status = M.get_status()
  if status.exists then
    return {
      buf = status.has_buffer and status.has_buffer or nil,
      win = status.has_window and status.has_window or nil,
      is_current = status.visible
    }
  end
  return nil
end

return M