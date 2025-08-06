-- Terminal State Management - 分離的狀態管理模組
-- 簡化狀態追蹤，提升效能和可維護性

local M = {}

-- 通用多終端狀態存儲
M.state = {
  terminals = {
    -- 每個終端的狀態結構：
    -- terminal_name = {
    --   buf = nil,
    --   win = nil,
    --   job_id = nil,
    --   created_at = nil,
    --   last_active = nil
    -- }
  },
  global = {
    last_active_terminal = nil,
    busy = false,
    busy_timeout = nil,
    operation_lock = false,  -- 防止並發操作
    lock_timeout = nil
  }
}

-- 安全的屬性檢查函數
function M.is_buf_valid(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

function M.is_win_valid(win)
  return win and vim.api.nvim_win_is_valid(win)
end

-- 獲取 buffer 選項的安全函數
function M.get_buf_option_safe(buf, option, default)
  if not M.is_buf_valid(buf) then
    return default
  end
  local success, result = pcall(function()
    return vim.bo[buf][option]
  end)
  return success and result or default
end

-- 獲取 buffer 變數的安全函數
function M.get_buf_var_safe(buf, var, default)
  if not M.is_buf_valid(buf) then
    return default
  end
  local success, result = pcall(vim.api.nvim_buf_get_var, buf, var)
  return success and result or default
end

-- 通用終端狀態管理函數
-- 獲取終端狀態
function M.get_terminal_state(name)
  if not name then
    return nil
  end
  return M.state.terminals[name]
end

-- 設定終端狀態
function M.set_terminal_state(name, state)
  if not name then
    return false
  end
  
  -- 初始化終端狀態結構
  if not M.state.terminals[name] then
    M.state.terminals[name] = {
      buf = nil,
      win = nil,
      job_id = nil,
      created_at = nil,
      last_active = nil
    }
  end
  
  -- 更新狀態
  for key, value in pairs(state) do
    M.state.terminals[name][key] = value
  end
  
  -- 更新最後活躍時間
  M.state.terminals[name].last_active = vim.fn.localtime()
  
  return true
end

-- 移除終端狀態
function M.remove_terminal_state(name)
  if not name then
    return false
  end
  
  M.state.terminals[name] = nil
  
  -- 如果移除的是最後活躍的終端，清除全域記錄
  if M.state.global.last_active_terminal == name then
    M.state.global.last_active_terminal = nil
  end
  
  return true
end

-- 列出所有終端
function M.list_terminals()
  local terminals = {}
  for name, _ in pairs(M.state.terminals) do
    table.insert(terminals, name)
  end
  return terminals
end

-- 清理無效狀態（支援多終端）
function M.cleanup_invalid_state()
  for name, terminal in pairs(M.state.terminals) do
    -- 清理無效視窗
    if terminal.win and not M.is_win_valid(terminal.win) then
      terminal.win = nil
    end
    
    -- 清理無效 buffer
    if terminal.buf and not M.is_buf_valid(terminal.buf) then
      terminal.buf = nil
      terminal.job_id = nil
    end
    
    -- 如果終端完全無效，移除它
    if not terminal.buf and not terminal.win and not terminal.job_id then
      M.state.terminals[name] = nil
      
      -- 如果是最後活躍的終端，清除記錄
      if M.state.global.last_active_terminal == name then
        M.state.global.last_active_terminal = nil
      end
    end
  end
end

-- 清理特定終端的無效狀態
function M.cleanup_terminal_state(name)
  local terminal = M.state.terminals[name]
  if not terminal then
    return
  end
  
  -- 清理無效視窗
  if terminal.win and not M.is_win_valid(terminal.win) then
    terminal.win = nil
  end
  
  -- 清理無效 buffer
  if terminal.buf and not M.is_buf_valid(terminal.buf) then
    terminal.buf = nil
    terminal.job_id = nil
  end
end

-- 設定忙碌狀態 - 修復版防死鎖
function M.set_busy(busy)
  if busy then
    M.state.global.busy = true
    -- 清除舊的超時器
    if M.state.global.busy_timeout then
      pcall(vim.fn.timer_stop, M.state.global.busy_timeout)
      M.state.global.busy_timeout = nil
    end
    
    -- 使用 vim.fn.timer_start 替代 vim.defer_fn 獲得正確的 timer ID
    M.state.global.busy_timeout = vim.fn.timer_start(3000, function()
      if M.state.global.busy then
        vim.notify("⚠️  終端操作超時，自動解鎖", vim.log.levels.WARN)
        M.state.global.busy = false
        M.state.global.busy_timeout = nil
      end
    end)
  else
    M.state.global.busy = false
    -- 安全清除超時器
    if M.state.global.busy_timeout then
      pcall(vim.fn.timer_stop, M.state.global.busy_timeout)
      M.state.global.busy_timeout = nil
    end
  end
end

-- 檢查是否忙碌
function M.is_busy()
  return M.state.global.busy
end

-- 設定最後活躍的終端
function M.set_last_active(terminal_name)
  M.state.global.last_active_terminal = terminal_name
  
  -- 同時更新該終端的最後活躍時間
  if M.state.terminals[terminal_name] then
    M.state.terminals[terminal_name].last_active = vim.fn.localtime()
  end
end

-- 獲取最後活躍的終端
function M.get_last_active()
  return M.state.global.last_active_terminal
end

-- 重置所有狀態
function M.reset()
  -- 安全關閉所有終端的視窗
  for name, terminal in pairs(M.state.terminals) do
    if M.is_win_valid(terminal.win) then
      pcall(vim.api.nvim_win_close, terminal.win, true)
    end
    
    -- 安全刪除 buffer
    if M.is_buf_valid(terminal.buf) then
      pcall(vim.api.nvim_buf_delete, terminal.buf, { force = true })
    end
  end
  
  -- 安全清除超時器
  if M.state.global.busy_timeout then
    pcall(vim.fn.timer_stop, M.state.global.busy_timeout)
  end
  if M.state.global.lock_timeout then
    pcall(vim.fn.timer_stop, M.state.global.lock_timeout)
  end
  
  -- 重置狀態
  M.state = {
    terminals = {},
    global = {
      last_active_terminal = nil,
      busy = false,
      busy_timeout = nil,
      operation_lock = false,
      lock_timeout = nil
    }
  }
end

-- 重置特定終端狀態
function M.reset_terminal(name)
  local terminal = M.state.terminals[name]
  if not terminal then
    return false
  end
  
  -- 安全關閉視窗
  if M.is_win_valid(terminal.win) then
    pcall(vim.api.nvim_win_close, terminal.win, true)
  end
  
  -- 安全刪除 buffer
  if M.is_buf_valid(terminal.buf) then
    pcall(vim.api.nvim_buf_delete, terminal.buf, { force = true })
  end
  
  -- 移除終端狀態
  M.remove_terminal_state(name)
  
  return true
end

-- 獲取完整狀態（用於調試）
function M.get_status()
  M.cleanup_invalid_state()
  return vim.tbl_deep_extend("force", {}, M.state)
end

-- 向後相容性支援
-- 為 Gemini 終端提供舊 API 的相容性
function M.get_gemini_state()
  return M.get_terminal_state("gemini")
end

function M.set_gemini_state(state)
  return M.set_terminal_state("gemini", state)
end

-- 狀態隔離檢查函數
function M.validate_state_isolation()
  local terminals = M.list_terminals()
  
  -- 檢查終端間是否有狀態洩露
  for i, name1 in ipairs(terminals) do
    for j, name2 in ipairs(terminals) do
      if i ~= j then
        local terminal1 = M.get_terminal_state(name1)
        local terminal2 = M.get_terminal_state(name2)
        
        -- 檢查是否共享相同的 buffer 或 window
        if terminal1.buf and terminal2.buf and terminal1.buf == terminal2.buf then
          return false, string.format("終端 %s 和 %s 共享相同的 buffer", name1, name2)
        end
        
        if terminal1.win and terminal2.win and terminal1.win == terminal2.win then
          return false, string.format("終端 %s 和 %s 共享相同的 window", name1, name2)
        end
      end
    end
  end
  
  return true, "狀態隔離檢查通過"
end

return M