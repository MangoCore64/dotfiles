-- 終端 UI 管理模組
-- 從原始 Gemini 適配器提取並通用化的浮動視窗管理
--
-- 功能特色：
-- - 通用化的浮動視窗創建和管理
-- - 響應式視窗大小調整
-- - 多種視窗配置選項
-- - 安全的視窗操作與錯誤處理
-- - 支援多種邊框樣式和配置

local M = {}

-- 預設 UI 配置
local DEFAULT_CONFIG = {
  -- 視窗大小 (相對於螢幕的比例)
  width_ratio = 0.8,
  height_ratio = 0.8,
  
  -- 最小視窗大小
  min_width = 40,
  min_height = 10,
  
  -- 視窗樣式
  relative = "editor",
  style = "minimal",
  border = "double",
  
  -- 位置 (如果不指定，將自動居中)
  row = nil,
  col = nil,
  
  -- 額外選項
  focusable = true,
  zindex = 50
}

-- 支援的邊框樣式
local BORDER_STYLES = {
  none = "none",
  single = "single",
  double = "double",
  rounded = "rounded",
  solid = "solid",
  shadow = "shadow"
}

-- 計算響應式視窗大小
local function calculate_window_size(config)
  local width = math.floor(vim.o.columns * (config.width_ratio or DEFAULT_CONFIG.width_ratio))
  local height = math.floor(vim.o.lines * (config.height_ratio or DEFAULT_CONFIG.height_ratio))
  
  -- 應用最小大小限制
  width = math.max(width, config.min_width or DEFAULT_CONFIG.min_width)
  height = math.max(height, config.min_height or DEFAULT_CONFIG.min_height)
  
  -- 確保不超過螢幕大小
  width = math.min(width, vim.o.columns - 4)
  height = math.min(height, vim.o.lines - 4)
  
  return width, height
end

-- 計算視窗位置（居中）
local function calculate_window_position(width, height, config)
  local row = config.row
  local col = config.col
  
  -- 如果沒有指定位置，自動居中
  if not row then
    row = math.floor((vim.o.lines - height) / 2)
  end
  
  if not col then
    col = math.floor((vim.o.columns - width) / 2)
  end
  
  return row, col
end

-- 驗證邊框樣式
local function validate_border_style(border)
  if not border then
    return DEFAULT_CONFIG.border
  end
  
  if BORDER_STYLES[border] then
    return border
  end
  
  -- 如果是自定義邊框數組，直接返回
  if type(border) == "table" then
    return border
  end
  
  -- 無效的邊框樣式，使用預設值
  vim.notify("⚠️ 無效的邊框樣式: " .. tostring(border) .. "，使用預設樣式", vim.log.levels.WARN)
  return DEFAULT_CONFIG.border
end

-- 創建浮動視窗配置
local function create_window_config(width, height, row, col, user_config)
  return {
    relative = user_config.relative or DEFAULT_CONFIG.relative,
    width = width,
    height = height,
    row = row,
    col = col,
    style = user_config.style or DEFAULT_CONFIG.style,
    border = validate_border_style(user_config.border),
    focusable = user_config.focusable ~= false, -- 預設為 true
    zindex = user_config.zindex or DEFAULT_CONFIG.zindex
  }
end

-- 增強的 Buffer 驗證函數
local function validate_buffer_with_retry(buf, max_retries)
  max_retries = max_retries or 3
  
  for i = 1, max_retries do
    -- 基本檢查
    if not buf then
      return false, "Buffer 為 nil"
    end
    
    -- 檢查 buffer 是否有效
    if not vim.api.nvim_buf_is_valid(buf) then
      if i < max_retries then
        -- 短暫等待後重試，處理時序問題
        vim.wait(10) -- 等待 10ms
      else
        return false, "Buffer 無效 (ID: " .. tostring(buf) .. ")"
      end
    else
      -- Buffer 有效，進行額外檢查
      local success, buf_info = pcall(function()
        return {
          loaded = vim.api.nvim_buf_is_loaded(buf),
          name = vim.api.nvim_buf_get_name(buf),
          line_count = vim.api.nvim_buf_line_count(buf)
        }
      end)
      
      if success then
        -- 詳細的 buffer 資訊，幫助診斷
        vim.notify(string.format("✅ Buffer 驗證通過 (ID: %d, 載入: %s, 行數: %d)", 
          buf, buf_info.loaded and "是" or "否", buf_info.line_count), vim.log.levels.DEBUG)
        return true, nil
      else
        if i < max_retries then
          vim.wait(10)
        else
          return false, "無法獲取 Buffer 資訊"
        end
      end
    end
  end
  
  return false, "Buffer 驗證失敗（多次重試後）"
end

-- 主要的浮動視窗創建函數
function M.create_floating_window(buf, user_config)
  -- 使用增強的 buffer 驗證
  local buf_valid, buf_error = validate_buffer_with_retry(buf)
  if not buf_valid then
    vim.notify("🔍 Buffer 驗證詳細錯誤: " .. tostring(buf_error), vim.log.levels.ERROR)
    return nil, "無效的 buffer: " .. tostring(buf_error)
  end
  
  -- 合併使用者配置和預設配置
  local config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, user_config or {})
  
  -- 計算視窗尺寸和位置
  local width, height = calculate_window_size(config)
  local row, col = calculate_window_position(width, height, config)
  
  -- 創建視窗配置
  local win_config = create_window_config(width, height, row, col, config)
  
  -- 安全地創建浮動視窗（增強錯誤處理）
  vim.notify(string.format("🪟 準備創建浮動視窗 (Buffer: %d, 尺寸: %dx%d)", 
    buf, width, height), vim.log.levels.DEBUG)
  
  local success, win_or_error = pcall(vim.api.nvim_open_win, buf, true, win_config)
  
  if not success then
    -- 詳細的錯誤診斷
    local error_details = {
      buffer_id = buf,
      buffer_valid = vim.api.nvim_buf_is_valid(buf),
      window_config = win_config,
      error_message = tostring(win_or_error)
    }
    
    vim.notify("🔍 視窗創建失敗詳細資訊: " .. vim.inspect(error_details), vim.log.levels.ERROR)
    
    return nil, "無法創建浮動視窗: " .. tostring(win_or_error)
  end
  
  local win = win_or_error
  
  -- 設置視窗選項（如果需要）
  if config.title and win then
    pcall(vim.api.nvim_win_set_option, win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
  end
  
  return win, nil
end

-- Gemini 風格的浮動視窗（向後相容）
function M.create_gemini_window(buf)
  return M.create_floating_window(buf, {
    width_ratio = 0.9,
    height_ratio = 0.9,
    border = "double"
  })
end

-- Claude Code 風格的浮動視窗
function M.create_claude_window(buf)
  return M.create_floating_window(buf, {
    width_ratio = 0.8,
    height_ratio = 0.8,
    border = "rounded"
  })
end

-- 小型浮動視窗（適合簡單命令）
function M.create_small_window(buf)
  return M.create_floating_window(buf, {
    width_ratio = 0.6,
    height_ratio = 0.4,
    border = "single"
  })
end

-- 全螢幕浮動視窗
function M.create_fullscreen_window(buf)
  return M.create_floating_window(buf, {
    width_ratio = 0.95,
    height_ratio = 0.95,
    border = "shadow"
  })
end

-- 安全關閉視窗
function M.close_window(win)
  if not win then
    return true
  end
  
  if not vim.api.nvim_win_is_valid(win) then
    return true -- 已經關閉
  end
  
  local success = pcall(function()
    -- 檢查是否是標籤頁中的最後一個視窗
    local wins_in_tab = vim.api.nvim_tabpage_list_wins(0)
    if #wins_in_tab <= 1 then
      -- 如果是最後一個視窗，創建一個空 buffer
      vim.cmd('enew')
    else
      -- 否則直接關閉視窗
      vim.api.nvim_win_close(win, true)
    end
  end)
  
  return success
end

-- 檢查視窗是否可見
function M.is_window_visible(win)
  return win and vim.api.nvim_win_is_valid(win)
end

-- 切換到指定視窗
function M.focus_window(win)
  if not M.is_window_visible(win) then
    return false
  end
  
  local success = pcall(vim.api.nvim_set_current_win, win)
  if success then
    vim.cmd("startinsert")
  end
  
  return success
end

-- 獲取視窗資訊
function M.get_window_info(win)
  if not M.is_window_visible(win) then
    return nil
  end
  
  local success, config = pcall(vim.api.nvim_win_get_config, win)
  if not success then
    return nil
  end
  
  return {
    window = win,
    valid = true,
    config = config,
    width = config.width,
    height = config.height,
    row = config.row,
    col = config.col
  }
end

-- 調整視窗大小
function M.resize_window(win, new_config)
  if not M.is_window_visible(win) then
    return false, "視窗無效"
  end
  
  -- 獲取當前配置
  local success, current_config = pcall(vim.api.nvim_win_get_config, win)
  if not success then
    return false, "無法獲取視窗配置"
  end
  
  -- 合併新配置
  local merged_config = vim.tbl_deep_extend("force", current_config, new_config or {})
  
  -- 重新計算尺寸
  if new_config.width_ratio or new_config.height_ratio then
    local width, height = calculate_window_size(new_config)
    merged_config.width = width
    merged_config.height = height
    
    -- 重新計算位置（居中）
    local row, col = calculate_window_position(width, height, new_config)
    merged_config.row = row
    merged_config.col = col
  end
  
  -- 應用新配置
  local resize_success = pcall(vim.api.nvim_win_set_config, win, merged_config)
  
  return resize_success, resize_success and "視窗大小調整成功" or "視窗大小調整失敗"
end

-- 健康檢查
function M.health_check()
  local issues = {}
  
  -- 檢查 Neovim 浮動視窗支援
  if not vim.api.nvim_open_win then
    table.insert(issues, "Neovim 版本不支援浮動視窗")
  end
  
  -- 檢查預設配置
  for key, value in pairs(DEFAULT_CONFIG) do
    if value == nil then
      table.insert(issues, string.format("預設配置 %s 為 nil", key))
    end
  end
  
  -- 檢查邊框樣式
  for style_name, style_value in pairs(BORDER_STYLES) do
    if type(style_value) ~= "string" then
      table.insert(issues, string.format("邊框樣式 %s 配置錯誤", style_name))
    end
  end
  
  return #issues == 0, issues
end

-- 獲取支援的配置選項
function M.get_supported_options()
  return {
    default_config = vim.tbl_deep_extend("force", {}, DEFAULT_CONFIG),
    border_styles = vim.tbl_deep_extend("force", {}, BORDER_STYLES),
    functions = {
      "create_floating_window",
      "create_gemini_window", 
      "create_claude_window",
      "create_small_window",
      "create_fullscreen_window",
      "close_window",
      "is_window_visible",
      "focus_window", 
      "get_window_info",
      "resize_window",
      "health_check"
    }
  }
end

return M