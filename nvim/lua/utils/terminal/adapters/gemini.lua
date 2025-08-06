-- 🔒 Gemini Terminal Adapter - 輕量安全版本
-- 專注於 Gemini CLI 特定功能的輕量適配器
-- 
-- 特色：
-- - 輕量化設計 (~95行)
-- - 保留關鍵安全機制
-- - 委託核心功能給 core.lua
-- - 向後相容 API

local M = {}
local core = require('utils.terminal.core')
local security = require('utils.terminal.security')

-- Gemini 終端配置
local GEMINI_CONFIG = {
  name = "gemini",
  command = "gemini",
  title = "Gemini CLI Terminal", 
  security_level = "high",
  ui_config = {
    width_ratio = 0.9,
    height_ratio = 0.9,
    border = "double"
  }
}

-- 基礎終端操作 (委託給 core.lua)
function M.show()
  local success, result = pcall(core.open_terminal, GEMINI_CONFIG)
  if not success then
    vim.notify("❌ 開啟 Gemini 終端失敗: " .. tostring(result), vim.log.levels.ERROR)
    return false
  end
  return result
end

function M.open()
  -- 向後相容別名
  return M.show()
end

function M.hide()
  return core.close_terminal("gemini")
end

function M.close()
  -- 向後相容別名
  return M.hide()
end

function M.toggle()
  return core.toggle_terminal("gemini", GEMINI_CONFIG)
end

function M.is_visible()
  return core.is_terminal_visible("gemini")
end

function M.get_status()
  return core.get_terminal_status("gemini")
end

-- 🔒 關鍵安全函數 (必須保留)
function M.security_audit()
  return security.security_audit()
end

function M.security_test()
  -- 簡化版但保留核心檢查
  vim.notify("🧪 開始 Gemini 終端安全測試...", vim.log.levels.INFO)
  
  local tests_passed = 0
  local tests_failed = 0
  local issues = {}
  
  -- 測試 1: Gemini 命令可用性
  local gemini_valid, gemini_path, gemini_error = security.validate_command("gemini")
  if gemini_valid then
    vim.notify("✅ Gemini 命令驗證通過: " .. gemini_path, vim.log.levels.INFO)
    tests_passed = tests_passed + 1
  else
    local error_msg = "Gemini 命令驗證失敗: " .. tostring(gemini_error)
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
  vim.notify(string.format("🧪 Gemini 安全測試完成: %d/%d 通過", tests_passed, total_tests), 
    success and vim.log.levels.INFO or vim.log.levels.WARN)
  
  return success, issues
end

function M.show_config()
  local security_config = security.get_security_config()
  local gemini_status = M.get_status()
  
  -- 簡化版配置顯示，保留安全檢查
  local config_info = "=== 🔧 Gemini 終端配置 ===\n"
  
  -- 顯示 Gemini 命令路徑
  local gemini_path = security_config.secure_commands and security_config.secure_commands.gemini or "未配置"
  config_info = config_info .. string.format("Gemini 路徑: %s\n", gemini_path)
  
  -- 顯示終端狀態
  config_info = config_info .. string.format("終端狀態: %s\n", gemini_status.visible and "可見" or "隱藏")
  config_info = config_info .. string.format("存在: %s\n", gemini_status.exists and "是" or "否")
  
  if gemini_status.created_at then
    config_info = config_info .. string.format("創建時間: %s\n", 
      os.date("%Y-%m-%d %H:%M:%S", gemini_status.created_at))
  end
  
  -- 顯示 PATH 中的 gemini 位置
  local path_gemini = vim.fn.exepath("gemini")
  if path_gemini ~= "" then
    config_info = config_info .. string.format("PATH 中的 gemini: %s\n", path_gemini)
  else
    config_info = config_info .. "⚠️ 在 PATH 中未找到 gemini\n"
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
  -- 委託給核心但添加 Gemini 特定檢查
  local core_valid, core_issues = core.health_check()
  local issues = core_issues or {}
  
  -- Gemini 特定檢查
  if not GEMINI_CONFIG.name or not GEMINI_CONFIG.command then
    table.insert(issues, "Gemini 配置不完整")
  end
  
  -- 檢查 Gemini 命令可用性
  local gemini_valid, _, gemini_error = security.validate_command("gemini")
  if not gemini_valid then
    table.insert(issues, "Gemini 命令不可用: " .. tostring(gemini_error))
  end
  
  return #issues == 0, issues
end

-- 🔧 向後相容功能 (簡化版)
function M.destroy()
  return core.destroy_terminal("gemini")
end

function M.restart()
  vim.notify("🔄 重啟 Gemini 終端...", vim.log.levels.INFO)
  
  local destroy_success = M.destroy()
  if not destroy_success then
    vim.notify("⚠️ 無法銷毀現有終端", vim.log.levels.WARN)
  end
  
  vim.defer_fn(function()
    local show_success = M.show()
    if show_success then
      vim.notify("✅ Gemini 終端重啟成功", vim.log.levels.INFO)
    else
      vim.notify("❌ Gemini 終端重啟失敗", vim.log.levels.ERROR)
    end
  end, 100)
  
  return true
end

-- 簡化的狀態管理 (向後相容)
function M.find_existing_gemini_terminal()
  local status = M.get_status()
  if status.exists then
    return {
      buf = status.has_buffer and status.has_buffer or nil,
      win = status.has_window and status.has_window or nil,
      managed = true
    }
  end
  return nil
end

-- 遷移功能（向後相容）
function M.migrate_from_old_version()
  vim.notify("🔄 開始從舊版本遷移 Gemini 終端配置...", vim.log.levels.INFO)
  
  -- 清理可能存在的舊狀態
  local destroy_success = M.destroy()
  if not destroy_success then
    vim.notify("📋 清理舊狀態時遇到問題", vim.log.levels.WARN)
  end
  
  -- 運行健康檢查
  local health_valid, health_issues = M.health_check()
  if health_valid then
    vim.notify("✅ 遷移完成，系統狀態正常", vim.log.levels.INFO)
  else
    vim.notify("⚠️ 遷移完成，但發現問題:", vim.log.levels.WARN)
    for _, issue in ipairs(health_issues) do
      vim.notify("  • " .. issue, vim.log.levels.WARN)
    end
  end
  
  return health_valid
end

-- 調試功能
function M.debug_info()
  local info = {
    module_version = "Lightweight Adapter",
    dependencies = {
      core = core ~= nil,
      security = security ~= nil
    },
    config = GEMINI_CONFIG,
    status = M.get_status(),
    health = M.health_check()
  }
  
  vim.notify("🐛 Gemini 終端調試資訊:", vim.log.levels.INFO)  
  vim.notify(vim.inspect(info), vim.log.levels.INFO)
  
  return info
end

return M