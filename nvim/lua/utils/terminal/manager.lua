-- Terminal Manager V3 - 增強錯誤恢復版本
-- 簡化的協調器，使用模組化設計提升效能和可維護性
-- 新增功能：智能錯誤恢復、異常狀態處理、操作重試機制

local M = {}

-- 載入子模組
local state = require('utils.terminal.state')
local claude = require('utils.terminal.adapters.claude')
local gemini = require('utils.terminal.adapters.gemini')

-- 錯誤恢復配置
local RECOVERY_CONFIG = {
  max_retries = 3,           -- 最大重試次數
  retry_delay = 100,         -- 重試延遲 (ms)
  timeout_threshold = 5000,  -- 操作超時閾值 (ms)
  health_check_interval = 30 -- 健康檢查間隔 (秒)
}

-- 操作統計
local operation_stats = {
  total_operations = 0,
  successful_operations = 0,
  failed_operations = 0,
  recovery_operations = 0,
  last_health_check = 0
}

-- 錯誤類型分類
local ERROR_TYPES = {
  TIMEOUT = "操作超時",
  INVALID_STATE = "無效狀態",
  RESOURCE_CONFLICT = "資源衝突",
  COMMAND_FAILED = "命令執行失敗",
  RECOVERY_FAILED = "恢復失敗"
}

-- 智能錯誤恢復函數
local function recover_from_error(error_type, context)
  operation_stats.recovery_operations = operation_stats.recovery_operations + 1
  
  vim.notify(string.format("🔧 開始錯誤恢復: %s", error_type), vim.log.levels.WARN)
  
  -- 根據錯誤類型選擇恢復策略
  if error_type == ERROR_TYPES.INVALID_STATE then
    -- 清理無效狀態
    state.cleanup_invalid_state()
    vim.wait(RECOVERY_CONFIG.retry_delay)
    return true
    
  elseif error_type == ERROR_TYPES.RESOURCE_CONFLICT then
    -- 釋放所有終端資源
    claude.destroy()
    gemini.destroy()
    vim.wait(RECOVERY_CONFIG.retry_delay * 2)
    return true
    
  elseif error_type == ERROR_TYPES.TIMEOUT then
    -- 強制解除忙碌狀態
    state.set_busy(false)
    vim.wait(RECOVERY_CONFIG.retry_delay)
    return true
    
  elseif error_type == ERROR_TYPES.COMMAND_FAILED then
    -- 重新初始化適配器
    local claude_ok = pcall(claude.migrate_from_old_version)
    local gemini_ok = pcall(gemini.migrate_from_old_version)
    return claude_ok and gemini_ok
  end
  
  return false
end

-- 執行操作並進行錯誤處理和重試
local function execute_with_retry(operation_name, func, ...)
  local args = {...}
  operation_stats.total_operations = operation_stats.total_operations + 1
  
  for attempt = 1, RECOVERY_CONFIG.max_retries do
    local start_time = vim.fn.reltime()
    local success, result = pcall(func, unpack(args))
    local elapsed_time = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000
    
    if success then
      operation_stats.successful_operations = operation_stats.successful_operations + 1
      if attempt > 1 then
        vim.notify(string.format("✅ %s 重試成功 (第 %d 次嘗試)", operation_name, attempt), vim.log.levels.INFO)
      end
      return result
    end
    
    -- 分析錯誤類型
    local error_msg = tostring(result)
    local error_type = ERROR_TYPES.COMMAND_FAILED -- 預設錯誤類型
    
    if elapsed_time > RECOVERY_CONFIG.timeout_threshold then
      error_type = ERROR_TYPES.TIMEOUT
    elseif error_msg:find("buffer") or error_msg:find("window") then
      error_type = ERROR_TYPES.INVALID_STATE
    elseif error_msg:find("busy") or error_msg:find("lock") then
      error_type = ERROR_TYPES.RESOURCE_CONFLICT
    end
    
    vim.notify(string.format("⚠️ %s 第 %d 次嘗試失敗: %s", operation_name, attempt, error_msg), vim.log.levels.WARN)
    
    -- 如果不是最後一次嘗試，進行錯誤恢復
    if attempt < RECOVERY_CONFIG.max_retries then
      local recovery_success = recover_from_error(error_type, {
        operation = operation_name,
        attempt = attempt,
        error = error_msg
      })
      
      if recovery_success then
        vim.notify(string.format("🔄 錯誤恢復成功，準備重試 %s", operation_name), vim.log.levels.INFO)
        vim.wait(RECOVERY_CONFIG.retry_delay * attempt) -- 遞增延遲
      else
        vim.notify(string.format("❌ 錯誤恢復失敗，跳過重試"), vim.log.levels.ERROR)
        break
      end
    end
  end
  
  -- 所有重試都失敗
  operation_stats.failed_operations = operation_stats.failed_operations + 1
  vim.notify(string.format("❌ %s 操作最終失敗，已重試 %d 次", operation_name, RECOVERY_CONFIG.max_retries), vim.log.levels.ERROR)
  return false
end

-- 增強的防並發包裝函數
local function with_lock(func, operation_name)
  return function(...)
    -- 檢查並發狀態
    if state.is_busy() then
      vim.notify("⏳ 終端操作進行中，請稍候...", vim.log.levels.WARN)
      return false
    end
    
    -- 執行定期健康檢查
    local current_time = vim.fn.localtime()
    if current_time - operation_stats.last_health_check > RECOVERY_CONFIG.health_check_interval then
      M.auto_health_check()
      operation_stats.last_health_check = current_time
    end
    
    state.set_busy(true)
    local result = execute_with_retry(operation_name or "未知操作", func, ...)
    state.set_busy(false)
    
    return result
  end
end

-- 主要 API 函數（增強錯誤恢復版本）
M.toggle_claude_code = with_lock(function()
  if claude.is_visible() then
    return claude.close()
  else
    -- 先隱藏 gemini，避免衝突
    if gemini.is_visible() then
      gemini.hide()
      vim.wait(50) -- 短暫延遲確保清理完成
    end
    return claude.open()
  end
end, "切換 Claude Code")

M.toggle_gemini = with_lock(function()
  if gemini.is_visible() then
    return gemini.hide()
  else
    -- 先關閉 Claude Code，避免衝突
    if claude.is_visible() then
      claude.close()
      vim.wait(50) -- 短暫延遲確保清理完成
    end
    return gemini.show()
  end
end, "切換 Gemini")

-- 智能終端切換 - 增強錯誤恢復版本
M.switch_terminal = with_lock(function()
  local claude_visible = claude.is_visible()
  local gemini_visible = gemini.is_visible()
  
  -- 檢查是否存在異常狀態 (兩個都可見)
  if claude_visible and gemini_visible then
    vim.notify("⚠️ 檢測到異常狀態：兩個終端同時可見，正在修復...", vim.log.levels.WARN)
    claude.close()
    gemini.hide()
    vim.wait(100)
    -- 重新判斷狀態
    claude_visible = claude.is_visible()
    gemini_visible = gemini.is_visible()
  end
  
  if claude_visible then
    -- Claude Code 活躍，切換到 Gemini
    local close_success = claude.close()
    if close_success then
      vim.wait(50) -- 確保資源清理
      local show_success = gemini.show()
      if show_success then
        state.set_last_active("gemini")
        return true
      end
    end
    return false
    
  elseif gemini_visible then
    -- Gemini 活躍，切換到 Claude Code
    local hide_success = gemini.hide()
    if hide_success then
      vim.wait(50) -- 確保資源清理
      local open_success = claude.open()
      if open_success then
        state.set_last_active("claude_code")
        return true
      end
    end
    return false
    
  else
    -- 都沒開啟，開啟最後使用的或預設 Claude Code
    local last_active = state.get_last_active()
    if last_active == "gemini" then
      local show_success = gemini.show()
      if show_success then
        state.set_last_active("gemini")
        return true
      end
    else
      local open_success = claude.open()
      if open_success then
        state.set_last_active("claude_code")
        return true
      end
    end
    return false
  end
end, "智能終端切換")

-- 獲取狀態資訊
function M.get_status()
  local claude_info = claude.find_claude_terminal()
  
  return {
    claude_code = {
      available = claude_info ~= nil,
      visible = claude.is_visible(),
      buf = claude_info and claude_info.buf or nil,
      win = claude_info and claude_info.win or nil,
      is_current = claude_info and claude_info.is_current or false
    },
    gemini = (function()
      local gemini_state = state.get_terminal_state("gemini") or {}
      return {
        available = gemini_state.buf ~= nil,
        visible = gemini.is_visible(),
        buf = gemini_state.buf,
        win = gemini_state.win,
        job_id = gemini_state.job_id
      }
    end)(),
    last_active = state.get_last_active(),
    busy = state.is_busy()
  }
end

-- 清理無效狀態
function M.cleanup()
  state.cleanup_invalid_state()
  vim.notify("🔧 終端狀態已清理", vim.log.levels.INFO)
  return M.get_status()
end

-- 完全重置
function M.reset()
  state.reset()
  -- 重置統計
  operation_stats = {
    total_operations = 0,
    successful_operations = 0,
    failed_operations = 0,
    recovery_operations = 0,
    last_health_check = 0
  }
  vim.notify("🔄 終端管理器已重置", vim.log.levels.INFO)
  return M.get_status()
end

-- 自動健康檢查
function M.auto_health_check()
  local issues = {}
  
  -- 檢查終端狀態一致性
  local claude_visible = claude.is_visible()
  local gemini_visible = gemini.is_visible()
  
  if claude_visible and gemini_visible then
    table.insert(issues, "兩個終端同時可見")
    -- 自動修復：關閉所有終端
    claude.close()
    gemini.hide()
  end
  
  -- 檢查適配器健康狀態
  local claude_health_ok, claude_issues = claude.health_check()
  if not claude_health_ok then
    vim.list_extend(issues, claude_issues or {})
  end
  
  local gemini_health_ok, gemini_issues = gemini.health_check()
  if not gemini_health_ok then
    vim.list_extend(issues, gemini_issues or {})
  end
  
  -- 檢查狀態隔離
  local state_valid, state_message = state.validate_state_isolation()
  if not state_valid then
    table.insert(issues, "狀態隔離問題: " .. state_message)
    -- 自動修復：清理無效狀態
    state.cleanup_invalid_state()
  end
  
  if #issues > 0 then
    vim.notify(string.format("⚠️ 健康檢查發現 %d 個問題，已自動修復", #issues), vim.log.levels.WARN)
  end
  
  return #issues == 0, issues
end

-- 手動健康檢查（詳細版本）
function M.health_check()
  vim.notify("🏥 開始完整健康檢查...", vim.log.levels.INFO)
  
  local health_report = {
    timestamp = os.date("%Y-%m-%d %H:%M:%S"),
    overall_status = "健康",
    issues = {},
    modules = {},
    statistics = operation_stats
  }
  
  -- 檢查各個適配器
  local claude_health_ok, claude_issues = claude.health_check()
  health_report.modules.claude = {
    status = claude_health_ok and "健康" or "有問題",
    issues = claude_issues or {}
  }
  
  local gemini_health_ok, gemini_issues = gemini.health_check()
  health_report.modules.gemini = {
    status = gemini_health_ok and "健康" or "有問題",
    issues = gemini_issues or {}
  }
  
  -- 檢查狀態管理
  local state_valid, state_message = state.validate_state_isolation()
  health_report.modules.state = {
    status = state_valid and "健康" or "有問題",
    issues = state_valid and {} or {state_message}
  }
  
  -- 檢查終端一致性
  local claude_visible = claude.is_visible()
  local gemini_visible = gemini.is_visible()
  if claude_visible and gemini_visible then
    table.insert(health_report.issues, "兩個終端同時可見（異常狀態）")
    health_report.overall_status = "需要修復"
  end
  
  -- 匯總所有問題
  for _, module_info in pairs(health_report.modules) do
    vim.list_extend(health_report.issues, module_info.issues)
  end
  
  -- 判斷整體狀態
  if #health_report.issues > 0 then
    health_report.overall_status = "有問題"
  end
  
  -- 顯示健康報告
  vim.notify(string.format("📋 健康檢查完成 - 狀態: %s", health_report.overall_status), 
    health_report.overall_status == "健康" and vim.log.levels.INFO or vim.log.levels.WARN)
  
  if #health_report.issues > 0 then
    for _, issue in ipairs(health_report.issues) do
      vim.notify("  • " .. issue, vim.log.levels.WARN)
    end
  end
  
  return health_report
end

-- 獲取操作統計
function M.get_statistics()
  local success_rate = operation_stats.total_operations > 0 and 
    (operation_stats.successful_operations / operation_stats.total_operations * 100) or 0
  
  return {
    total_operations = operation_stats.total_operations,
    successful_operations = operation_stats.successful_operations,
    failed_operations = operation_stats.failed_operations,
    recovery_operations = operation_stats.recovery_operations,
    success_rate = string.format("%.1f%%", success_rate),
    last_health_check = operation_stats.last_health_check > 0 and 
      os.date("%Y-%m-%d %H:%M:%S", operation_stats.last_health_check) or "從未執行"
  }
end

-- 強制錯誤恢復
function M.force_recovery()
  vim.notify("🆘 開始強制錯誤恢復...", vim.log.levels.WARN)
  
  -- 解除鎖定
  state.set_busy(false)
  
  -- 銷毀所有終端
  pcall(claude.destroy)
  pcall(gemini.destroy)
  
  -- 清理狀態
  state.cleanup_invalid_state()
  
  -- 重置統計
  operation_stats.recovery_operations = operation_stats.recovery_operations + 1
  
  vim.notify("✅ 強制錯誤恢復完成", vim.log.levels.INFO)
  
  return M.get_status()
end

-- 性能診斷
function M.performance_diagnostic()
  local results = {}
  
  -- 測試切換性能
  local start_time = vim.fn.reltime()
  local switch_success = M.switch_terminal()
  local switch_time = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000
  
  results.switch_time_ms = switch_time
  results.switch_performance = switch_time < 200 and "優秀" or switch_time < 500 and "良好" or "需要優化"
  results.switch_success = switch_success
  
  -- 關閉測試終端
  if switch_success then
    M.switch_terminal() -- 切換回去
  end
  
  -- 記憶體使用
  results.memory_usage_kb = collectgarbage("count")
  
  -- 統計資訊
  results.statistics = M.get_statistics()
  
  return results
end

-- 除錯資訊
function M.debug_info()
  local debug_data = {
    version = "V3 (Enhanced Error Recovery)",
    config = RECOVERY_CONFIG,
    statistics = M.get_statistics(),
    health_report = M.health_check(),
    performance = M.performance_diagnostic(),
    current_status = M.get_status()
  }
  
  vim.notify("🐛 終端管理器除錯資訊:", vim.log.levels.INFO)
  vim.notify(vim.inspect(debug_data), vim.log.levels.INFO)
  
  return debug_data
end

return M