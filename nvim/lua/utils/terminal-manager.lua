-- Terminal Manager V3 - 簡化穩定版本
-- 重構策略：簡化狀態管理，提高穩定性和可維護性

local M = {}
local error_handler = require('utils.error-handler')

-- 簡化的狀態管理
local state = {
  gemini = {
    buf = nil,
    win = nil,
    job_id = nil
  },
  last_active = nil,
  busy = false  -- 簡化的操作鎖
}

-- 安全工具函數
local function get_buf_option_safe(buf, option, default)
  if not vim.api.nvim_buf_is_valid(buf) then
    return default
  end
  local success, result = pcall(function()
    return vim.bo[buf][option]
  end)
  return success and result or default
end

local function get_buf_var_safe(buf, var, default)
  if not vim.api.nvim_buf_is_valid(buf) then
    return default
  end
  local success, result = pcall(vim.api.nvim_buf_get_var, buf, var)
  return success and result or default
end

-- 簡化的 Claude Code 檢測函數
local function find_claude_code_terminal()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- 首先檢查當前窗口
  if vim.api.nvim_buf_is_valid(current_buf) then
    local buf_ft = get_buf_option_safe(current_buf, 'filetype', '')
    if buf_ft == 'terminal' then
      local term_name = get_buf_var_safe(current_buf, 'term_title', '')
      local buf_name = vim.api.nvim_buf_get_name(current_buf)
      
      if term_name:match('[Cc]laude') or term_name:match('claude%-code') or 
         buf_name:match('[Cc]laude') or buf_name:match('claude%-code') then
        return { buf = current_buf, win = current_win, is_current = true }
      end
    end
  end
  
  -- 檢查所有終端 buffer
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buf_ft = get_buf_option_safe(buf, 'filetype', '')
      if buf_ft == 'terminal' then
        local term_name = get_buf_var_safe(buf, 'term_title', '')
        local buf_name = vim.api.nvim_buf_get_name(buf)
        
        if term_name:match('[Cc]laude') or term_name:match('claude%-code') or 
           buf_name:match('[Cc]laude') or buf_name:match('claude%-code') then
          -- 檢查是否有對應的視窗
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
              return { buf = buf, win = win, is_current = false }
            end
          end
          return { buf = buf, win = nil, is_current = false }
        end
      end
    end
  end
  
  return nil
end

-- 檢查 Claude Code 是否可見
local function is_claude_code_visible()
  local claude_info = find_claude_code_terminal()
  return claude_info and claude_info.win and vim.api.nvim_win_is_valid(claude_info.win)
end

-- 簡化的 Claude Code 關閉函數
local function close_claude_code()
  local claude_info = find_claude_code_terminal()
  
  if not claude_info then
    return true -- 已經關閉
  end
  
  -- 首先嘗試使用 ClaudeCode 命令 toggle
  local success, err = pcall(function()
    vim.cmd('ClaudeCode')
  end)
  
  if success then
    return true
  end
  
  -- 如果命令失敗，嘗試關閉視窗
  if claude_info.win and vim.api.nvim_win_is_valid(claude_info.win) then
    success, err = pcall(function()
      local wins_in_tab = vim.api.nvim_tabpage_list_wins(0)
      if #wins_in_tab <= 1 then
        vim.cmd('enew')
      else
        vim.api.nvim_win_close(claude_info.win, true)
      end
    end)
    
    if success then
      return true
    end
  end
  
  vim.notify("⚠️ 無法關閉 Claude Code: " .. tostring(err), vim.log.levels.WARN)
  return false
end

-- 檢查 Gemini 是否可見
local function is_gemini_visible()
  local terminal = state.gemini
  return terminal.win and vim.api.nvim_win_is_valid(terminal.win)
end

-- 簡化的 Gemini 隱藏函數
local function hide_gemini()
  if not is_gemini_visible() then
    return true
  end
  
  local success, err = pcall(function()
    local wins_in_tab = vim.api.nvim_tabpage_list_wins(0)
    if #wins_in_tab <= 1 then
      vim.cmd('enew')
    else
      vim.api.nvim_win_close(state.gemini.win, true)
    end
  end)
  
  if success then
    state.gemini.win = nil
    return true
  else
    vim.notify("⚠️ 無法隱藏 Gemini: " .. tostring(err), vim.log.levels.WARN)
    return false
  end
end

local function show_gemini()
  local terminal = state.gemini
  
  -- 如果已經可見，只需切換到該視窗
  if is_gemini_visible() then
    vim.api.nvim_set_current_win(terminal.win)
    vim.cmd("startinsert")
    return true
  end
  
  -- 如果 buffer 存在但視窗不存在，重新創建視窗
  if terminal.buf and vim.api.nvim_buf_is_valid(terminal.buf) then
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.9)
    
    local success, win_or_err = pcall(vim.api.nvim_open_win, terminal.buf, true, {
      relative = "editor",
      width = math.max(width, 40),
      height = math.max(height, 10),
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "double"
    })
    
    if success then
      terminal.win = win_or_err
      vim.cmd("startinsert")
      return true
    else
      vim.notify("⚠️ 無法創建 Gemini 視窗: " .. tostring(win_or_err), vim.log.levels.ERROR)
      return false
    end
  end
  
  -- 安全驗證和執行外部命令
  local function safe_execute_terminal_command(cmd_name)
    -- 定義允許的終端命令白名單
    local allowed_terminal_commands = {
      gemini = true,
      ["claude-code"] = true,
      ["claude"] = true
    }
    
    -- 驗證命令是否在白名單中
    if not allowed_terminal_commands[cmd_name] then
      error_handler.security_error("不允許的終端命令被阻止", {
        command = cmd_name,
        allowed_commands = vim.tbl_keys(allowed_terminal_commands)
      })
      return false, nil
    end
    
    -- 檢查命令是否存在
    if vim.fn.executable(cmd_name) == 0 then
      error_handler.error("終端命令未找到", {
        command = cmd_name,
        message = "請確認已正確安裝該命令"
      })
      return false, nil
    end
    
    -- 安全執行命令
    local success, job_id = pcall(vim.fn.termopen, cmd_name)
    if not success or job_id <= 0 then
      vim.notify("❌ 無法啟動終端命令: " .. cmd_name .. " (job_id: " .. tostring(job_id) .. ")", vim.log.levels.ERROR)
      return false, nil
    end
    
    return true, job_id
  end
  
  -- 創建新的 Gemini 終端
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local buf, win, job_id
  
  -- 創建 buffer
  local success, buf_or_err = pcall(vim.api.nvim_create_buf, false, true)
  if not success then
    vim.notify("❌ 無法創建 Gemini buffer: " .. tostring(buf_or_err), vim.log.levels.ERROR)
    return false
  end
  buf = buf_or_err
  
  -- 創建視窗
  success, win_or_err = pcall(vim.api.nvim_open_win, buf, true, {
    relative = "editor",
    width = math.max(width, 40),
    height = math.max(height, 10),
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "double"
  })
  
  if not success then
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.notify("❌ 無法創建 Gemini 視窗: " .. tostring(win_or_err), vim.log.levels.ERROR)
    return false
  end
  win = win_or_err
  
  -- 安全啟動終端命令
  local cmd_success, job_result = safe_execute_terminal_command("gemini")
  if not cmd_success then
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
    return false
  end
  job_id = job_result
  
  -- 保存狀態
  terminal.buf = buf
  terminal.win = win
  terminal.job_id = job_id
  
  vim.cmd("startinsert")
  return true
end

-- 主要 API 函數
function M.toggle_claude_code()
  if state.busy then
    vim.notify("⏳ 操作進行中，請稍候", vim.log.levels.WARN)
    return
  end
  
  state.busy = true
  
  local success = pcall(function()
    if is_claude_code_visible() then
      -- Claude Code 已開啟，嘗試關閉
      if close_claude_code() then
        state.last_active = "gemini"
      end
    else
      -- Claude Code 未開啟，開啟它
      hide_gemini() -- 先隱藏 gemini
      vim.cmd('ClaudeCode')
      state.last_active = "claude_code"
    end
  end)
  
  state.busy = false
  
  if not success then
    vim.notify("❌ Claude Code 切換失敗", vim.log.levels.ERROR)
  end
end

function M.toggle_gemini()
  if state.busy then
    vim.notify("⏳ 操作進行中，請稍候", vim.log.levels.WARN)
    return
  end
  
  state.busy = true
  
  local success = pcall(function()
    if is_gemini_visible() then
      hide_gemini()
      state.last_active = "claude_code"
    else
      -- 先關閉 Claude Code（如果開啟）
      close_claude_code()
      if show_gemini() then
        state.last_active = "gemini"
      end
    end
  end)
  
  state.busy = false
  
  if not success then
    vim.notify("❌ Gemini 切換失敗", vim.log.levels.ERROR)
  end
end

function M.switch_terminal()
  if state.busy then
    vim.notify("⏳ 操作進行中，請稍候", vim.log.levels.WARN)
    return
  end
  
  -- 檢測當前狀態並切換到另一個
  if is_claude_code_visible() then
    -- Claude Code 是當前活躍的，切換到 Gemini
    M.toggle_claude_code() -- 關閉 Claude Code
    vim.defer_fn(function() 
      if not state.busy then
        M.toggle_gemini() 
      end
    end, 50) -- 稍後開啟 Gemini
  elseif is_gemini_visible() then
    -- Gemini 是當前活躍的，切換到 Claude Code
    M.toggle_gemini() -- 關閉 Gemini
    vim.defer_fn(function() 
      if not state.busy then
        M.toggle_claude_code() 
      end
    end, 50) -- 稍後開啟 Claude Code
  else
    -- 都沒開啟，開啟最後使用的或預設 Claude Code
    if state.last_active == "gemini" then
      M.toggle_gemini()
    else
      M.toggle_claude_code()
    end
  end
end

function M.get_status()
  local claude_info = find_claude_code_terminal()
  
  return {
    claude_code = {
      available = claude_info ~= nil,
      visible = is_claude_code_visible(),
      buf = claude_info and claude_info.buf or nil,
      win = claude_info and claude_info.win or nil,
      is_current = claude_info and claude_info.is_current or false
    },
    gemini = {
      available = state.gemini.buf ~= nil,
      visible = is_gemini_visible(),
      buf = state.gemini.buf,
      win = state.gemini.win,
      job_id = state.gemini.job_id
    },
    last_active = state.last_active,
    busy = state.busy
  }
end

function M.cleanup()
  state.busy = false
  
  -- 清理無效的 gemini 狀態
  if state.gemini.win and not vim.api.nvim_win_is_valid(state.gemini.win) then
    state.gemini.win = nil
  end
  
  if state.gemini.buf and not vim.api.nvim_buf_is_valid(state.gemini.buf) then
    state.gemini.buf = nil
    state.gemini.job_id = nil
  end
  
  vim.notify("🔧 終端狀態已清理", vim.log.levels.INFO)
  return M.get_status()
end

function M.reset()
  -- 完全重置所有狀態
  state.busy = false
  state.last_active = nil
  
  -- 清理 Gemini 狀態
  if state.gemini.win and vim.api.nvim_win_is_valid(state.gemini.win) then
    pcall(vim.api.nvim_win_close, state.gemini.win, true)
  end
  
  if state.gemini.buf and vim.api.nvim_buf_is_valid(state.gemini.buf) then
    pcall(vim.api.nvim_buf_delete, state.gemini.buf, { force = true })
  end
  
  state.gemini = {
    buf = nil,
    win = nil,
    job_id = nil
  }
  
  vim.notify("🔄 終端管理器已重置", vim.log.levels.INFO)
  return M.get_status()
end

return M