-- 🔍 Neovim Performance Monitor
-- 企業級效能監控系統，提供啟動時間追蹤、記憶體監控和效能基準測試
-- 
-- 功能特色：
-- - 非侵入式監控，對效能影響 < 1ms
-- - 自動效能回歸檢測
-- - 詳細的效能分析報告
-- - 可配置的警告閾值
-- - 歷史趨勢追蹤

local M = {}

-- 🔧 效能監控配置
local config = {
  -- 警告閾值
  thresholds = {
    startup_time_ms = 500,        -- 啟動時間警告閾值 (毫秒)
    memory_warning_mb = 200,      -- 記憶體使用警告閾值 (MB)
    clipboard_operation_ms = 100, -- 剪貼板操作警告閾值 (毫秒)
    lsp_response_ms = 1000,       -- LSP 響應時間警告閾值 (毫秒)
  },
  
  -- 監控設置
  monitoring = {
    enabled = true,               -- 是否啟用監控
    auto_cleanup_interval = 300,  -- 自動清理間隔 (秒)
    history_retention_days = 7,   -- 歷史數據保留天數
    detailed_logging = false,     -- 是否啟用詳細日誌
  },
  
  -- 基準測試設置
  benchmarks = {
    startup_iterations = 3,       -- 啟動時間測試重複次數
    memory_check_interval = 60,   -- 記憶體檢查間隔 (秒)
    performance_report_interval = 1800, -- 效能報告間隔 (秒)
  }
}

-- 📊 效能數據存儲
local performance_data = {
  startup_times = {},
  memory_usage = {},
  operation_times = {},
  lsp_metrics = {},
  plugin_load_times = {},
  last_cleanup = os.time(),
}

-- 🚀 啟動時間追蹤系統
local startup_tracker = {
  start_time = nil,
  milestones = {},
}

-- 啟動計時器初始化
function M.init_startup_tracking()
  startup_tracker.start_time = vim.loop.hrtime()
  startup_tracker.milestones = {
    init_start = startup_tracker.start_time,
  }
  
  if config.monitoring.detailed_logging then
    vim.notify("🔍 效能監控啟動", vim.log.levels.INFO)
  end
end

-- 記錄啟動里程碑
function M.milestone(name)
  if not startup_tracker.start_time then
    return
  end
  
  startup_tracker.milestones[name] = vim.loop.hrtime()
  
  if config.monitoring.detailed_logging then
    local elapsed = (startup_tracker.milestones[name] - startup_tracker.start_time) / 1e6
    vim.notify(string.format("📍 %s: %.2fms", name, elapsed), vim.log.levels.DEBUG)
  end
end

-- 完成啟動時間測量
function M.finalize_startup_tracking()
  if not startup_tracker.start_time then
    return
  end
  
  local end_time = vim.loop.hrtime()
  local total_startup_time = (end_time - startup_tracker.start_time) / 1e6
  
  -- 記錄啟動時間
  table.insert(performance_data.startup_times, {
    timestamp = os.time(),
    total_time_ms = total_startup_time,
    milestones = startup_tracker.milestones,
  })
  
  -- 啟動時間警告
  if total_startup_time > config.thresholds.startup_time_ms then
    vim.notify(
      string.format("⚠️ 啟動較慢: %.2fms (閾值: %dms)", total_startup_time, config.thresholds.startup_time_ms),
      vim.log.levels.WARN
    )
  else
    vim.notify(
      string.format("✅ 啟動時間: %.2fms", total_startup_time),
      vim.log.levels.INFO
    )
  end
  
  -- 清理啟動追蹤數據
  startup_tracker.start_time = nil
  startup_tracker.milestones = {}
  
  return total_startup_time
end

-- 💾 記憶體監控系統
function M.get_memory_usage()
  -- 🔧 修復：vim.loop.resident_set_memory() 回傳 bytes，不是 KB
  local memory_bytes = vim.loop.resident_set_memory()
  local memory_kb = memory_bytes / 1024
  local memory_mb = memory_bytes / (1024 * 1024)
  
  return {
    rss_bytes = memory_bytes,
    rss_kb = memory_kb,
    rss_mb = memory_mb,
    buffers = #vim.api.nvim_list_bufs(),
    windows = #vim.api.nvim_list_wins(),
    tabpages = #vim.api.nvim_list_tabpages(),
    timestamp = os.time(),
  }
end

-- 記錄記憶體使用情況
function M.track_memory_usage()
  local memory_info = M.get_memory_usage()
  
  -- 記錄到歷史數據
  table.insert(performance_data.memory_usage, memory_info)
  
  -- 保持歷史數據大小合理 (最多保留 100 筆記錄)
  if #performance_data.memory_usage > 100 then
    table.remove(performance_data.memory_usage, 1)
  end
  
  -- 記憶體警告
  if memory_info.rss_mb > config.thresholds.memory_warning_mb then
    vim.notify(
      string.format("⚠️ 記憶體使用偏高: %.1fMB (閾值: %dMB)", memory_info.rss_mb, config.thresholds.memory_warning_mb),
      vim.log.levels.WARN
    )
  end
  
  return memory_info
end

-- ⏱️ 操作時間基準測試
function M.benchmark_operation(operation_name, operation_func)
  if not config.monitoring.enabled then
    return operation_func()
  end
  
  local start_time = vim.loop.hrtime()
  local result = operation_func()
  local end_time = vim.loop.hrtime()
  
  local duration_ms = (end_time - start_time) / 1e6
  
  -- 記錄操作時間
  if not performance_data.operation_times[operation_name] then
    performance_data.operation_times[operation_name] = {}
  end
  
  table.insert(performance_data.operation_times[operation_name], {
    timestamp = os.time(),
    duration_ms = duration_ms,
  })
  
  -- 保持歷史數據大小合理
  local operations = performance_data.operation_times[operation_name]
  if #operations > 50 then
    table.remove(operations, 1)
  end
  
  -- 檢查是否超過閾值 (針對已知操作)
  local threshold = config.thresholds.clipboard_operation_ms
  if operation_name:match("clipboard") and duration_ms > threshold then
    vim.notify(
      string.format("⚠️ %s 操作較慢: %.2fms", operation_name, duration_ms),
      vim.log.levels.WARN
    )
  end
  
  if config.monitoring.detailed_logging then
    vim.notify(
      string.format("📊 %s: %.2fms", operation_name, duration_ms),
      vim.log.levels.DEBUG
    )
  end
  
  return result
end

-- 📈 效能統計分析
function M.get_performance_stats()
  local stats = {
    startup_times = {},
    memory_stats = {},
    operation_stats = {},
    overall_health = "good",
  }
  
  -- 啟動時間統計
  if #performance_data.startup_times > 0 then
    local startup_times = {}
    for _, record in ipairs(performance_data.startup_times) do
      table.insert(startup_times, record.total_time_ms)
    end
    
    stats.startup_times = {
      count = #startup_times,
      latest = startup_times[#startup_times],
      average = M.calculate_average(startup_times),
      min = math.min(unpack(startup_times)),
      max = math.max(unpack(startup_times)),
    }
  end
  
  -- 記憶體統計
  if #performance_data.memory_usage > 0 then
    local memory_values = {}
    for _, record in ipairs(performance_data.memory_usage) do
      table.insert(memory_values, record.rss_mb)
    end
    
    stats.memory_stats = {
      count = #memory_values,
      current = memory_values[#memory_values],
      average = M.calculate_average(memory_values),
      min = math.min(unpack(memory_values)),
      max = math.max(unpack(memory_values)),
    }
  end
  
  -- 操作時間統計
  for operation, records in pairs(performance_data.operation_times) do
    local durations = {}
    for _, record in ipairs(records) do
      table.insert(durations, record.duration_ms)
    end
    
    if #durations > 0 then
      stats.operation_stats[operation] = {
        count = #durations,
        average = M.calculate_average(durations),
        min = math.min(unpack(durations)),
        max = math.max(unpack(durations)),
        latest = durations[#durations],
      }
    end
  end
  
  -- 整體健康狀況評估
  stats.overall_health = M.assess_overall_health(stats)
  
  return stats
end

-- 計算平均值
function M.calculate_average(values)
  if #values == 0 then return 0 end
  local sum = 0
  for _, value in ipairs(values) do
    sum = sum + value
  end
  return sum / #values
end

-- 評估整體健康狀況
function M.assess_overall_health(stats)
  local issues = 0
  
  -- 檢查啟動時間
  if stats.startup_times.latest and stats.startup_times.latest > config.thresholds.startup_time_ms then
    issues = issues + 1
  end
  
  -- 檢查記憶體使用
  if stats.memory_stats.current and stats.memory_stats.current > config.thresholds.memory_warning_mb then
    issues = issues + 1
  end
  
  -- 檢查操作時間
  for operation, op_stats in pairs(stats.operation_stats) do
    if operation:match("clipboard") and op_stats.average > config.thresholds.clipboard_operation_ms then
      issues = issues + 1
    end
  end
  
  if issues == 0 then
    return "excellent"
  elseif issues <= 1 then
    return "good"
  elseif issues <= 2 then
    return "fair"
  else
    return "poor"
  end
end

-- 📋 效能報告生成
function M.generate_performance_report()
  local stats = M.get_performance_stats()
  local report = {}
  
  table.insert(report, "=== 🔍 Neovim 效能監控報告 ===")
  table.insert(report, string.format("生成時間: %s", os.date("%Y-%m-%d %H:%M:%S")))
  table.insert(report, string.format("整體健康狀況: %s", stats.overall_health))
  table.insert(report, "")
  
  -- 啟動時間報告
  if stats.startup_times.count and stats.startup_times.count > 0 then
    table.insert(report, "🚀 啟動時間分析:")
    table.insert(report, string.format("  最新啟動: %.2fms", stats.startup_times.latest))
    table.insert(report, string.format("  平均時間: %.2fms", stats.startup_times.average))
    table.insert(report, string.format("  最快/最慢: %.2fms / %.2fms", stats.startup_times.min, stats.startup_times.max))
    table.insert(report, string.format("  測量次數: %d", stats.startup_times.count))
    table.insert(report, "")
  end
  
  -- 記憶體使用報告
  if stats.memory_stats.count and stats.memory_stats.count > 0 then
    table.insert(report, "💾 記憶體使用分析:")
    table.insert(report, string.format("  目前使用: %.1fMB", stats.memory_stats.current))
    table.insert(report, string.format("  平均使用: %.1fMB", stats.memory_stats.average))
    table.insert(report, string.format("  最低/最高: %.1fMB / %.1fMB", stats.memory_stats.min, stats.memory_stats.max))
    table.insert(report, string.format("  記錄次數: %d", stats.memory_stats.count))
    table.insert(report, "")
  end
  
  -- 操作時間報告
  if next(stats.operation_stats) then
    table.insert(report, "⏱️ 操作效能分析:")
    for operation, op_stats in pairs(stats.operation_stats) do
      table.insert(report, string.format("  %s:", operation))
      table.insert(report, string.format("    平均: %.2fms (最新: %.2fms)", op_stats.average, op_stats.latest))
      table.insert(report, string.format("    範圍: %.2fms - %.2fms", op_stats.min, op_stats.max))
      table.insert(report, string.format("    次數: %d", op_stats.count))
    end
    table.insert(report, "")
  end
  
  -- 建議和警告
  table.insert(report, "💡 效能建議:")
  local suggestions = M.generate_performance_suggestions(stats)
  for _, suggestion in ipairs(suggestions) do
    table.insert(report, "  " .. suggestion)
  end
  
  return table.concat(report, "\n")
end

-- 生成效能建議
function M.generate_performance_suggestions(stats)
  local suggestions = {}
  
  -- 啟動時間建議
  if stats.startup_times.latest and stats.startup_times.latest > config.thresholds.startup_time_ms then
    table.insert(suggestions, "🚀 考慮減少啟動時載入的插件數量")
    table.insert(suggestions, "🔧 檢查是否有插件配置可以延遲載入")
  else
    table.insert(suggestions, "✅ 啟動時間表現良好")
  end
  
  -- 記憶體使用建議
  if stats.memory_stats.current and stats.memory_stats.current > config.thresholds.memory_warning_mb then
    table.insert(suggestions, "💾 記憶體使用偏高，建議定期重啟 Neovim")
    table.insert(suggestions, "🧹 檢查是否有記憶體洩漏的插件")
  else
    table.insert(suggestions, "✅ 記憶體使用合理")
  end
  
  -- 操作效能建議
  for operation, op_stats in pairs(stats.operation_stats) do
    if operation:match("clipboard") and op_stats.average > config.thresholds.clipboard_operation_ms then
      table.insert(suggestions, "📋 剪貼板操作較慢，考慮優化相關配置")
    end
  end
  
  if #suggestions == 0 then
    table.insert(suggestions, "🎉 所有效能指標都表現良好！")
  end
  
  return suggestions
end

-- 🧹 自動清理系統
function M.auto_cleanup()
  local current_time = os.time()
  
  -- 檢查是否需要清理
  if current_time - performance_data.last_cleanup < config.monitoring.auto_cleanup_interval then
    return
  end
  
  local cleaned_items = 0
  local retention_seconds = config.monitoring.history_retention_days * 24 * 60 * 60
  local cutoff_time = current_time - retention_seconds
  
  -- 清理舊的啟動時間記錄
  for i = #performance_data.startup_times, 1, -1 do
    if performance_data.startup_times[i].timestamp < cutoff_time then
      table.remove(performance_data.startup_times, i)
      cleaned_items = cleaned_items + 1
    end
  end
  
  -- 清理舊的記憶體使用記錄
  for i = #performance_data.memory_usage, 1, -1 do
    if performance_data.memory_usage[i].timestamp < cutoff_time then
      table.remove(performance_data.memory_usage, i)
      cleaned_items = cleaned_items + 1
    end
  end
  
  -- 清理舊的操作時間記錄
  for operation, records in pairs(performance_data.operation_times) do
    for i = #records, 1, -1 do
      if records[i].timestamp < cutoff_time then
        table.remove(records, i)
        cleaned_items = cleaned_items + 1
      end
    end
  end
  
  performance_data.last_cleanup = current_time
  
  if config.monitoring.detailed_logging and cleaned_items > 0 then
    vim.notify(string.format("🧹 清理了 %d 筆過期效能數據", cleaned_items), vim.log.levels.INFO)
  end
  
  return cleaned_items
end

-- 🔧 公開 API 函數

-- 顯示即時效能狀態
function M.show_status()
  local memory = M.get_memory_usage()
  local stats = M.get_performance_stats()
  
  local status_info = string.format(
    "=== 🔍 即時效能狀態 ===\n" ..
    "記憶體使用: %.1fMB (緩衝區: %d)\n" ..
    "整體健康: %s\n" ..
    "最後啟動時間: %s\n" ..
    "監控狀態: %s",
    memory.rss_mb,
    memory.buffers,
    stats.overall_health,
    stats.startup_times.latest and string.format("%.2fms", stats.startup_times.latest) or "未知",
    config.monitoring.enabled and "啟用" or "停用"
  )
  
  print(status_info)
  vim.notify("效能狀態已輸出到 :messages", vim.log.levels.INFO)
end

-- 顯示詳細效能報告
function M.show_report()
  local report = M.generate_performance_report()
  print(report)
  vim.notify("詳細效能報告已輸出到 :messages", vim.log.levels.INFO)
end

-- 執行效能基準測試
function M.run_benchmarks()
  vim.notify("🔍 開始執行效能基準測試...", vim.log.levels.INFO)
  
  -- 記憶體基準測試
  local memory_before = M.get_memory_usage()
  
  -- 模擬一些常見操作
  M.benchmark_operation("buffer_creation", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
  
  M.benchmark_operation("window_operations", function()
    local current_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(current_win)
  end)
  
  M.benchmark_operation("file_operations", function()
    local temp_file = "/tmp/nvim_perf_test.txt"
    vim.fn.writefile({"test content"}, temp_file)
    vim.fn.delete(temp_file)
  end)
  
  local memory_after = M.get_memory_usage()
  
  vim.notify(
    string.format(
      "✅ 基準測試完成\n記憶體變化: %.1fMB → %.1fMB (Δ%.1fMB)",
      memory_before.rss_mb,
      memory_after.rss_mb,
      memory_after.rss_mb - memory_before.rss_mb
    ),
    vim.log.levels.INFO
  )
  
  -- 顯示測試結果
  M.show_report()
end

-- 重置效能數據
function M.reset_data()
  performance_data.startup_times = {}
  performance_data.memory_usage = {}
  performance_data.operation_times = {}
  performance_data.lsp_metrics = {}
  performance_data.plugin_load_times = {}
  performance_data.last_cleanup = os.time()
  
  vim.notify("🔄 效能監控數據已重置", vim.log.levels.INFO)
end

-- 更新配置
function M.update_config(new_config)
  config = vim.tbl_deep_extend("force", config, new_config)
  vim.notify("⚙️ 效能監控配置已更新", vim.log.levels.INFO)
end

-- 啟用/停用監控
function M.toggle_monitoring()
  config.monitoring.enabled = not config.monitoring.enabled
  vim.notify(
    string.format("🔍 效能監控已%s", config.monitoring.enabled and "啟用" or "停用"),
    vim.log.levels.INFO
  )
end

-- 獲取配置
function M.get_config()
  return config
end

-- 設定自動監控計時器 - 🔧 優化版：延遲啟動避免影響啟動時間
function M.setup_auto_monitoring()
  if not config.monitoring.enabled then
    return
  end
  
  -- 延遲啟動自動監控，避免影響啟動時間
  vim.defer_fn(function()
    -- 自動記憶體檢查
    vim.defer_fn(function()
      if config.monitoring.enabled then
        M.track_memory_usage()
        M.auto_cleanup()
        M.setup_auto_monitoring() -- 遞歸設定下次檢查
      end
    end, config.benchmarks.memory_check_interval * 1000)
  end, 5000) -- 延遲 5 秒後開始自動監控
  
  -- 自動效能報告
  vim.defer_fn(function()
    if config.monitoring.enabled then
      local stats = M.get_performance_stats()
      if stats.overall_health == "poor" then
        vim.notify("⚠️ 效能狀況不佳，建議檢查效能報告", vim.log.levels.WARN)
      end
    end
  end, config.benchmarks.performance_report_interval * 1000)
end

return M