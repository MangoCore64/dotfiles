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

-- 簡化的 Buffer 驗證函數（UX 優化版）
local function validate_buffer_simple(buf)
  if not buf then
    return false, "Buffer 為 nil"
  end
  
  if not vim.api.nvim_buf_is_valid(buf) then
    return false, "Buffer 無效 (ID: " .. tostring(buf) .. ")"
  end
  
  -- 僅在 DEBUG 模式下提供詳細資訊，減少通知干擾
  if vim.log.levels.DEBUG >= vim.log.levels.WARN then
    vim.schedule(function()
      vim.notify(string.format("Buffer 驗證通過 (ID: %d)", buf), vim.log.levels.DEBUG)
    end)
  end
  
  return true, nil
end

-- 主要的浮動視窗創建函數
function M.create_floating_window(buf, user_config)
  -- 使用簡化的 buffer 驗證
  local buf_valid, buf_error = validate_buffer_simple(buf)
  if not buf_valid then
    return nil, "無效的 buffer: " .. tostring(buf_error)
  end
  
  -- 合併使用者配置和預設配置
  local config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, user_config or {})
  
  -- 計算視窗尺寸和位置
  local width, height = calculate_window_size(config)
  local row, col = calculate_window_position(width, height, config)
  
  -- 創建視窗配置
  local win_config = create_window_config(width, height, row, col, config)
  
  -- 優化的浮動視窗創建（快速且安靜）
  local success, win_or_error = pcall(vim.api.nvim_open_win, buf, true, win_config)
  
  if not success then
    -- 只在真正錯誤時通知，避免干擾
    if vim.log.levels.ERROR >= vim.log.levels.WARN then
      vim.notify("視窗創建失敗", vim.log.levels.ERROR)
    end
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

-- 性能測試函數
function M.benchmark_window_creation(iterations)
  iterations = iterations or 10
  local times = {}
  
  for i = 1, iterations do
    local start_time = vim.loop.hrtime()
    
    -- 創建測試 buffer
    local buf = vim.api.nvim_create_buf(false, true)
    
    -- 創建浮動視窗
    local win, err = M.create_floating_window(buf)
    
    local end_time = vim.loop.hrtime()
    local duration = (end_time - start_time) / 1000000 -- 轉換為毫秒
    
    table.insert(times, duration)
    
    -- 清理
    if win then
      M.close_window(win)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  
  -- 計算統計數據
  table.sort(times)
  local total = 0
  for _, time in ipairs(times) do
    total = total + time
  end
  
  return {
    iterations = iterations,
    average = total / iterations,
    median = times[math.ceil(iterations / 2)],
    min = times[1],
    max = times[iterations],
    total = total
  }
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
  
  -- 性能基準測試
  local benchmark = M.benchmark_window_creation(5)
  if benchmark.average > 50 then -- 如果平均創建時間超過 50ms
    table.insert(issues, string.format("視窗創建性能較慢 (平均: %.2fms)", benchmark.average))
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
      "benchmark_window_creation",
      "health_check"
    }
  }
end

return M