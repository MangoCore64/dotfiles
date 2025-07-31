-- Terminal Manager V2 - 智能檢測版本
-- 新策略：不試圖完全管理 Claude Code，而是智能檢測和配合其原生行為

local M = {}

-- 簡化的狀態管理
local state = {
  gemini = {
    active = false,
    buf = nil,
    win = nil,
    job_id = nil
  },
  last_active = nil,
  operation_lock = false
}

-- Claude Code 智能檢測函數（改進版）
local function detect_claude_code_status()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- 方法1: 檢查當前視窗是否為 Claude Code
  if vim.api.nvim_buf_is_valid(current_buf) then
    local buf_ft = vim.api.nvim_buf_get_option(current_buf, 'filetype')
    if buf_ft == 'terminal' then
      -- 嘗試獲取終端名稱
      local success, term_name = pcall(vim.api.nvim_buf_get_var, current_buf, 'term_title')
      if success and term_name and (term_name:match('[Cc]laude') or term_name:match('claude%-code')) then
        return { active = true, buf = current_buf, win = current_win, is_current = true }
      end
      
      -- 檢查 buffer 名稱
      local buf_name = vim.api.nvim_buf_get_name(current_buf)
      if buf_name:match('[Cc]laude') or buf_name:match('claude%-code') then
        return { active = true, buf = current_buf, win = current_win, is_current = true }
      end
    end
  end
  
  -- 方法2: 檢查所有終端 buffer
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buf_ft = vim.api.nvim_buf_get_option(buf, 'filetype')
      if buf_ft == 'terminal' then
        -- 檢查終端名稱
        local success, term_name = pcall(vim.api.nvim_buf_get_var, buf, 'term_title')
        if success and term_name and (term_name:match('[Cc]laude') or term_name:match('claude%-code')) then
          -- 檢查是否有對應的視窗
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
              return { active = true, buf = buf, win = win, is_current = false }
            end
          end
          return { active = false, buf = buf, win = nil, is_current = false }
        end
      end
    end
  end
  
  -- 方法3: 檢查所有浮動視窗中的終端
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= '' then -- 是浮動視窗
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_is_valid(buf) then
          local buf_ft = vim.api.nvim_buf_get_option(buf, 'filetype')
          if buf_ft == 'terminal' then
            return { active = true, buf = buf, win = win, is_current = (win == current_win) }
          end
        end
      end
    end
  end
  
  return { active = false, buf = nil, win = nil, is_current = false }
end

-- Claude Code 智能關閉函數
local function close_claude_code()
  local status = detect_claude_code_status()
  
  if not status.active then
    return true -- 已經關閉
  end
  
  -- 嘗試不同的關閉方法
  local success = false
  
  -- 方法1: 如果有有效視窗，嘗試關閉
  if status.win and vim.api.nvim_win_is_valid(status.win) then
    local ok, err = pcall(function()
      -- 檢查是否是最後一個視窗
      local wins_in_tab = vim.api.nvim_tabpage_list_wins(0)
      if #wins_in_tab <= 1 then
        vim.cmd('enew')
      else
        vim.api.nvim_win_close(status.win, true)
      end
    end)
    if ok then success = true end
  end
  
  -- 方法2: 嘗試使用 ClaudeCode 命令（某些插件支援 toggle）
  if not success then
    local ok, err = pcall(function()
      vim.cmd('ClaudeCode')
    end)
    if ok then success = true end
  end
  
  -- 方法3: 如果有 buffer，嘗試刪除
  if not success and status.buf and vim.api.nvim_buf_is_valid(status.buf) then
    local ok, err = pcall(function()
      vim.api.nvim_buf_delete(status.buf, { force = true })
    end)
    if ok then success = true end
  end
  
  return success
end

-- Gemini 管理（與之前相同）
local function hide_gemini()
  local terminal = state.gemini
  if not terminal.active then return end
  
  if terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
    local success, err = pcall(function()
      local wins_in_tab = vim.api.nvim_tabpage_list_wins(0)
      if #wins_in_tab <= 1 then
        vim.cmd('enew')
      else
        vim.api.nvim_win_close(terminal.win, true)
      end
    end)
    
    if success then
      terminal.active = false
      terminal.win = nil
    end
  end
end

local function show_gemini()
  local terminal = state.gemini
  
  -- 改進的狀態檢查：檢查 buffer 是否仍然有效（移除 terminal.active 檢查以修復重複開啟問題）
  if terminal.buf and vim.api.nvim_buf_is_valid(terminal.buf) then
    -- 檢查是否有對應的視窗
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == terminal.buf then
        terminal.win = win -- 更新視窗參考
        vim.api.nvim_set_current_win(win)
        return
      end
    end
    -- buffer 存在但沒有視窗，重新創建視窗
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.9)
    terminal.win = vim.api.nvim_open_win(terminal.buf, true, {
      relative = "editor",
      width = math.max(width, 40),
      height = math.max(height, 10),
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "double"
    })
    vim.cmd("startinsert")
    return
  end
  
  -- 檢查 gemini 命令
  if vim.fn.executable("gemini") == 0 then
    vim.notify("Gemini command not found. Please install gemini CLI.", vim.log.levels.ERROR)
    return
  end
  
  -- 創建浮動視窗
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local buf, win, job_id
  
  local success, err = pcall(function()
    buf = vim.api.nvim_create_buf(false, true)
    win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = math.max(width, 40),
      height = math.max(height, 10),
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "double"
    })
    
    job_id = vim.fn.termopen("gemini")
    if job_id <= 0 then
      error("Failed to start gemini terminal")
    end
  end)
  
  if not success then
    -- 完整回滾
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.notify("Failed to create Gemini floating terminal: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end
  
  terminal.buf = buf
  terminal.win = win
  terminal.job_id = job_id
  terminal.active = true
  
  vim.cmd("startinsert")
end

-- 主要 API 函數
function M.toggle_claude_code()
  if state.operation_lock then
    vim.notify("Operation in progress, please wait", vim.log.levels.WARN)
    return
  end
  state.operation_lock = true
  
  local success, err = pcall(function()
    local status = detect_claude_code_status()
    
    if status.active then
      -- Claude Code 已開啟，嘗試關閉
      local closed = close_claude_code()
      if closed then
        state.last_active = "gemini" -- 切換到 gemini 作為下次默認
      else
        vim.notify("Failed to close Claude Code", vim.log.levels.WARN)
      end
    else
      -- Claude Code 未開啟，開啟它
      hide_gemini() -- 先隱藏 gemini
      vim.cmd('ClaudeCode')
      state.last_active = "claude_code"
    end
  end)
  
  state.operation_lock = false
  
  if not success then
    vim.notify("Claude Code toggle failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
  end
end

function M.toggle_gemini()
  if state.operation_lock then
    vim.notify("Operation in progress, please wait", vim.log.levels.WARN)
    return
  end
  state.operation_lock = true
  
  local success, err = pcall(function()
    -- 重新檢查 gemini 狀態（修復狀態不同步問題）
    local terminal = state.gemini
    local actually_active = false
    
    if terminal.buf and vim.api.nvim_buf_is_valid(terminal.buf) then
      -- 檢查是否有對應的視窗
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == terminal.buf then
          actually_active = true
          terminal.win = win
          break
        end
      end
    end
    
    terminal.active = actually_active -- 同步狀態
    
    if actually_active then
      hide_gemini()
      state.last_active = "claude_code"
    else
      -- 先關閉 Claude Code（如果開啟）
      close_claude_code()
      show_gemini()
      state.last_active = "gemini"
    end
  end)
  
  state.operation_lock = false
  
  if not success then
    vim.notify("Gemini toggle failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
  end
end

function M.switch_terminal()
  if state.operation_lock then
    vim.notify("Operation in progress, please wait", vim.log.levels.WARN)
    return
  end
  
  -- 檢測當前狀態並切換到另一個
  local claude_status = detect_claude_code_status()
  
  if claude_status.active then
    -- Claude Code 是當前活躍的，切換到 Gemini
    M.toggle_claude_code() -- 關閉 Claude Code
    vim.defer_fn(function() M.toggle_gemini() end, 100) -- 稍後開啟 Gemini
  elseif state.gemini.active then
    -- Gemini 是當前活躍的，切換到 Claude Code
    M.toggle_gemini() -- 關閉 Gemini
    vim.defer_fn(function() M.toggle_claude_code() end, 100) -- 稍後開啟 Claude Code
  else
    -- 都沒開啟，開啟最後使用的或默認 Claude Code
    if state.last_active == "gemini" then
      M.toggle_gemini()
    else
      M.toggle_claude_code()
    end
  end
end

function M.get_status()
  local claude_status = detect_claude_code_status()
  
  -- 同步 Gemini 狀態 - 檢查視窗是否實際存在
  local gemini_actually_active = false
  if state.gemini.buf and vim.api.nvim_buf_is_valid(state.gemini.buf) then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == state.gemini.buf then
        gemini_actually_active = true
        break
      end
    end
  end
  state.gemini.active = gemini_actually_active
  
  return {
    claude_code = claude_status,
    gemini = state.gemini,
    last_active = state.last_active,
    operation_lock = state.operation_lock
  }
end

function M.fix_state()
  state.operation_lock = false
  
  -- 清理無效的 gemini 狀態
  if state.gemini.win and not vim.api.nvim_win_is_valid(state.gemini.win) then
    state.gemini.win = nil
    state.gemini.active = false
  end
  
  if state.gemini.buf and not vim.api.nvim_buf_is_valid(state.gemini.buf) then
    state.gemini.buf = nil
    state.gemini.job_id = nil
  end
  
  print("Terminal state fixed")
  return M.get_status()
end

return M