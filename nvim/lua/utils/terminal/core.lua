-- 終端管理核心模組
-- 提供統一、安全的終端管理 API
--
-- 功能特色：
-- - 統一的終端開啟/關閉/切換 API
-- - 集成安全驗證和路徑檢查
-- - 統一的錯誤處理和日誌記錄
-- - 支援多種終端類型的擴展

local M = {}
local security = require('utils.terminal.security')
local state = require('utils.terminal.state')
local ui = require('utils.terminal.ui')

-- 終端配置結構
local TerminalConfig = {
  name = "",           -- 終端名稱 (必需)
  command = "",        -- 執行命令 (必需) 
  title = "",          -- 視窗標題 (可選)
  security_level = "high", -- 安全等級 (high/medium/low)
  ui_config = {}       -- UI 配置 (可選)
}

-- 預設 UI 配置
local DEFAULT_UI_CONFIG = {
  relative = "editor",
  width = math.floor(vim.o.columns * 0.8),
  height = math.floor(vim.o.lines * 0.8),
  col = math.floor(vim.o.columns * 0.1),
  row = math.floor(vim.o.lines * 0.1),
  style = "minimal",
  border = "double"
}

-- 檢查終端是否可見
function M.is_terminal_visible(name)
  if not name then
    return false
  end
  
  local terminal = state.get_terminal_state(name)
  if not terminal then
    return false
  end
  
  return terminal.win and state.is_win_valid(terminal.win)
end

-- 創建浮動視窗（使用 UI 模組）
local function create_floating_window(buf, ui_config)
  if not buf or not state.is_buf_valid(buf) then
    return nil, "無效的 buffer"
  end
  
  -- 轉換舊的 DEFAULT_UI_CONFIG 格式到新的 UI 模組格式
  local converted_config = {}
  if ui_config then
    -- 如果有寬度/高度，轉換為比例
    if ui_config.width then
      converted_config.width_ratio = ui_config.width / vim.o.columns
    end
    if ui_config.height then
      converted_config.height_ratio = ui_config.height / vim.o.lines
    end
    
    -- 複製其他配置
    converted_config.relative = ui_config.relative
    converted_config.style = ui_config.style
    converted_config.border = ui_config.border
    converted_config.row = ui_config.row
    converted_config.col = ui_config.col
  end
  
  -- 使用 UI 模組創建視窗
  return ui.create_floating_window(buf, converted_config)
end


-- 安全執行命令並創建終端
local function safe_execute_terminal_command(cmd_name)
  -- 驗證命令安全性
  local valid, safe_path, error_msg = security.validate_command(cmd_name)
  if not valid then
    return false, nil, nil, nil, error_msg
  end
  
  -- 防止參數注入：檢查命令名稱中的危險字符
  local dangerous_chars = {";", "&", "|", "`", "$", "(", ")", "\0", "\r", "\n"}
  for _, char in ipairs(dangerous_chars) do
    if cmd_name:find(char, 1, true) then
      return false, nil, nil, nil, string.format("命令名稱包含危險字符: %s", cmd_name)
    end
  end
  
  -- 直接在當前 buffer 中執行 termopen（恢復重構前的成功模式）
  -- 使用驗證過的安全路徑執行命令
  local success, job_id = pcall(vim.fn.termopen, safe_path, {
    on_exit = function(job_id, exit_code, event)
      vim.schedule(function()
        vim.notify(string.format("🔍 終端 %s 結束 - 代碼: %d, 事件: %s", 
          cmd_name, exit_code, event), vim.log.levels.INFO)
        
        if exit_code ~= 0 then
          vim.notify(string.format("⚠️ 終端 %s 異常結束 (代碼: %d)", cmd_name, exit_code), vim.log.levels.WARN)
          
          -- 提供退出碼的詳細解釋
          local exit_explanations = {
            [1] = "一般錯誤",
            [2] = "命令用法錯誤", 
            [126] = "命令無法執行",
            [127] = "命令未找到",
            [128] = "無效的退出參數",
            [129] = "致命錯誤 (SIGHUP)",
            [130] = "用戶中斷 (Ctrl+C)",
            [143] = "終止信號 (SIGTERM)"
          }
          
          local explanation = exit_explanations[exit_code] or "未知錯誤"
          vim.notify(string.format("📋 退出碼 %d 說明: %s", exit_code, explanation), vim.log.levels.INFO)
        else
          vim.notify(string.format("✅ 終端 %s 正常結束", cmd_name), vim.log.levels.INFO)
        end
        
        -- 清理狀態
        state.cleanup_terminal_state(cmd_name)
      end)
    end
  })
  
  -- 獲取當前 buffer 作為終端 buffer
  local buf = vim.api.nvim_get_current_buf()
  
  if not success or not job_id or job_id <= 0 then
    -- 詳細的失敗診斷
    local failure_reason = "未知錯誤"
    if not success then
      failure_reason = "termopen 調用失敗"
    elseif not job_id then
      failure_reason = "job_id 為 nil"
    elseif job_id <= 0 then
      failure_reason = string.format("無效的 job_id: %d", job_id)
    end
    
    vim.notify(string.format("🔍 Termopen 失敗詳情 - 命令: %s, 原因: %s", safe_path, failure_reason), vim.log.levels.ERROR)
    
    return false, nil, nil, nil, "無法啟動終端程序: " .. failure_reason
  end
  
  -- 驗證 termopen 後 buffer 和 job 狀態
  vim.defer_fn(function()
    if not state.is_buf_valid(buf) then
      vim.notify(string.format("⚠️ 警告: Buffer %d 在 termopen 後變為無效，可能程序立即退出", buf), vim.log.levels.WARN)
    else
      vim.notify(string.format("✅ Termopen 成功 - Buffer: %d, Job: %d 狀態正常", buf, job_id), vim.log.levels.DEBUG)
    end
  end, 100) -- 100ms 後檢查
  
  -- 記錄安全執行日誌
  vim.notify(string.format("🔒 安全執行命令: %s -> %s (PID: %d)", 
    cmd_name, safe_path, job_id), vim.log.levels.INFO)
  
  return true, buf, job_id, safe_path, "終端程序啟動成功"
end

-- 統一的終端開啟 API
function M.open_terminal(config)
  if not config or not config.name or not config.command then
    vim.notify("❌ 終端配置不完整", vim.log.levels.ERROR)
    return false
  end
  
  -- 檢查是否已經開啟
  if M.is_terminal_visible(config.name) then
    -- 如果已經可見，只需切換焦點
    local terminal = state.get_terminal_state(config.name)
    if terminal and terminal.win then
      vim.api.nvim_set_current_win(terminal.win)
      vim.cmd("startinsert")
      return true
    end
  end
  
  -- 檢查是否已有 buffer 但視窗關閉
  local existing_terminal = state.get_terminal_state(config.name)
  if existing_terminal and existing_terminal.buf and 
     state.is_buf_valid(existing_terminal.buf) then
    
    -- 重新創建視窗
    local win, win_error = create_floating_window(existing_terminal.buf, config.ui_config)
    if not win then
      vim.notify("⚠️ 無法創建視窗: " .. tostring(win_error), vim.log.levels.ERROR)
      return false
    end
    
    -- 更新狀態
    state.set_terminal_state(config.name, { win = win })
    state.set_last_active(config.name)
    
    vim.cmd("startinsert")
    return true
  end
  
  -- 創建新的終端（恢復重構前的成功執行順序）
  vim.notify(string.format("🔧 為終端 %s 創建 buffer 和浮動視窗", config.name), vim.log.levels.DEBUG)
  
  -- 1. 創建 buffer
  local buf = vim.api.nvim_create_buf(false, true)
  if not buf or buf <= 0 then
    vim.notify("❌ 無法創建 buffer", vim.log.levels.ERROR)
    return false
  end
  
  -- 2. 創建浮動視窗
  local win, win_error = create_floating_window(buf, config.ui_config)
  if not win then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    vim.notify("⚠️ 無法創建視窗: " .. tostring(win_error), vim.log.levels.ERROR)
    return false
  end
  
  vim.notify(string.format("✅ 成功創建浮動視窗 (Buffer: %d, Window: %d)", buf, win), vim.log.levels.DEBUG)
  
  -- 3. 在浮動視窗中執行 termopen（這是關鍵！）
  local success, job_id, safe_path, error_msg = safe_execute_terminal_command(config.command)
  if not success then
    -- 清理失敗的視窗和 buffer
    pcall(vim.api.nvim_win_close, win, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    vim.notify("❌ 無法創建終端: " .. tostring(error_msg), vim.log.levels.ERROR)
    return false
  end
  
  -- 4. 更新 buffer 引用（termopen 後 buffer 可能改變）
  buf = vim.api.nvim_get_current_buf()
  
  vim.notify(string.format("✅ 成功在浮動視窗中啟動終端 (Buffer: %d, Job: %d)", buf, job_id), vim.log.levels.DEBUG)
  
  -- 保存狀態
  state.set_terminal_state(config.name, { 
    buf = buf, 
    win = win, 
    job_id = job_id,
    command = config.command,
    safe_path = safe_path,
    title = config.title or config.name,
    created_at = vim.fn.localtime()
  })
  
  state.set_last_active(config.name)
  
  vim.cmd("startinsert")
  return true
end

-- 統一的終端關閉 API
function M.close_terminal(name)
  if not name then
    vim.notify("❌ 終端名稱為空", vim.log.levels.ERROR)
    return false
  end
  
  local terminal = state.get_terminal_state(name)
  if not terminal then
    return true -- 已經關閉
  end
  
  -- 關閉視窗（使用 UI 模組）
  if terminal.win and state.is_win_valid(terminal.win) then
    local success = ui.close_window(terminal.win)
    
    if success then
      -- 更新狀態，只清除視窗，保留 buffer 以便重新開啟
      state.set_terminal_state(name, { win = nil })
      return true
    else
      vim.notify("⚠️ 無法關閉終端視窗", vim.log.levels.WARN)
      return false
    end
  end
  
  return true
end

-- 統一的終端切換 API
function M.toggle_terminal(name, config)
  if not name then
    vim.notify("❌ 終端名稱為空", vim.log.levels.ERROR)
    return false
  end
  
  if M.is_terminal_visible(name) then
    return M.close_terminal(name)
  else
    -- 如果沒有配置，使用預設配置
    local default_config = config or {
      name = name,
      command = name,
      title = name .. " Terminal"
    }
    return M.open_terminal(default_config)
  end
end

-- 完全銷毀終端（包括 buffer）
function M.destroy_terminal(name)
  if not name then
    vim.notify("❌ 終端名稱為空", vim.log.levels.ERROR)
    return false
  end
  
  local terminal = state.get_terminal_state(name)
  if not terminal then
    return true -- 已經銷毀
  end
  
  -- 關閉視窗（使用 UI 模組）
  if terminal.win and state.is_win_valid(terminal.win) then
    ui.close_window(terminal.win)
  end
  
  -- 刪除 buffer
  if terminal.buf and state.is_buf_valid(terminal.buf) then
    pcall(vim.api.nvim_buf_delete, terminal.buf, { force = true })
  end
  
  -- 移除狀態
  state.remove_terminal_state(name)
  
  return true
end

-- 獲取終端狀態資訊
function M.get_terminal_status(name)
  if not name then
    return nil
  end
  
  local terminal = state.get_terminal_state(name)
  if not terminal then
    return {
      name = name,
      exists = false,
      visible = false
    }
  end
  
  return {
    name = name,
    exists = true,
    visible = M.is_terminal_visible(name),
    has_buffer = terminal.buf and state.is_buf_valid(terminal.buf),
    has_window = terminal.win and state.is_win_valid(terminal.win),
    job_id = terminal.job_id,
    command = terminal.command,
    created_at = terminal.created_at,
    last_active = terminal.last_active
  }
end

-- 列出所有終端
function M.list_terminals()
  local terminals = state.list_terminals()
  local result = {}
  
  for _, name in ipairs(terminals) do
    table.insert(result, M.get_terminal_status(name))
  end
  
  return result
end

-- 健康檢查
function M.health_check()
  local issues = {}
  
  -- 檢查安全配置
  local security_valid, security_issues = security.validate_security_config()
  if not security_valid then
    vim.list_extend(issues, security_issues)
  end
  
  -- 檢查 UI 模組
  local ui_valid, ui_issues = ui.health_check()
  if not ui_valid then
    vim.list_extend(issues, ui_issues)
  end
  
  -- 檢查終端狀態一致性
  local state_valid, state_message = state.validate_state_isolation()
  if not state_valid then
    table.insert(issues, "狀態隔離問題: " .. state_message)
  end
  
  -- 檢查每個終端的狀態
  local terminals = state.list_terminals()
  for _, name in ipairs(terminals) do
    local status = M.get_terminal_status(name)
    if status.exists and status.has_buffer and 
       type(status.has_buffer) == "number" and not state.is_buf_valid(status.has_buffer) then
      table.insert(issues, string.format("終端 %s 有無效的 buffer", name))
    end
  end
  
  return #issues == 0, issues
end

return M