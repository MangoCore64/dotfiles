-- 配置驗證機制
-- 在啟動時檢查和驗證 NvChad 配置的完整性和正確性

local M = {}
local error_handler = require('utils.error-handler')

-- 驗證規則定義
local validation_rules = {
  -- LSP 配置驗證
  lsp = {
    required_files = {
      "lua/configs/lspconfig.lua"
    },
    required_plugins = {
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim"
    },
    check_function = function()
      local issues = {}
      
      -- 檢查 Mason LSP 名稱一致性
      local success, lspconfig = pcall(require, "configs.lspconfig")
      if success then
        -- 檢查是否有棄用的 API 調用
        local lsp_file = vim.fn.stdpath("config") .. "/lua/configs/lspconfig.lua"
        if vim.fn.filereadable(lsp_file) == 1 then
          local content = table.concat(vim.fn.readfile(lsp_file), "\n")
          if content:match("vim%.lsp%.enable") then
            table.insert(issues, "使用了已棄用的 vim.lsp.enable API")
          end
        end
      end
      
      return issues
    end
  },
  
  -- Plugin 配置驗證
  plugins = {
    required_files = {
      "lua/plugins/init.lua"
    },
    check_function = function()
      local issues = {}
      
      -- 檢查版本鎖定策略
      local plugins_file = vim.fn.stdpath("config") .. "/lua/plugins/init.lua"
      if vim.fn.filereadable(plugins_file) == 1 then
        local content = table.concat(vim.fn.readfile(plugins_file), "\n")
        
        -- 檢查是否有未鎖定版本的重要插件
        local important_plugins = {
          "claude%-code%.nvim",
          "gemini%.nvim",
          "copilot%.lua"
        }
        
        for _, plugin in ipairs(important_plugins) do
          if content:match(plugin) and not content:match(plugin .. '.*commit') and not content:match(plugin .. '.*tag') then
            table.insert(issues, "插件 " .. plugin .. " 沒有版本鎖定")
          end
        end
      end
      
      return issues
    end
  },
  
  -- 安全配置驗證
  security = {
    check_function = function()
      local issues = {}
      
      -- 檢查 OSC 52 預設設定
      local success, clipboard = pcall(require, "utils.clipboard")
      if success then
        -- 這裡我們無法直接存取 M_config，但可以檢查相關函數
        local clipboard_file = vim.fn.stdpath("config") .. "/lua/utils/clipboard.lua"
        if vim.fn.filereadable(clipboard_file) == 1 then
          local content = table.concat(vim.fn.readfile(clipboard_file), "\n")
          if content:match("enable_osc52%s*=%s*true") then
            table.insert(issues, "OSC 52 預設啟用可能有安全風險")
          end
        end
      end
      
      return issues
    end
  },
  
  -- 效能配置驗證
  performance = {
    check_function = function()
      local issues = {}
      
      -- 檢查是否有立即載入的非必要插件
      local plugins_file = vim.fn.stdpath("config") .. "/lua/plugins/init.lua"
      if vim.fn.filereadable(plugins_file) == 1 then
        local content = table.concat(vim.fn.readfile(plugins_file), "\n")
        
        -- 檢查可能影響啟動效能的配置
        if content:match("lazy%s*=%s*false") then
          local count = 0
          for _ in content:gmatch("lazy%s*=%s*false") do
            count = count + 1
          end
          if count > 3 then
            table.insert(issues, "過多插件設為立即載入 (lazy = false)，可能影響啟動效能")
          end
        end
      end
      
      return issues
    end
  }
}

-- 執行單一驗證規則
local function validate_rule(rule_name, rule)
  local issues = {}
  
  -- 檢查必要文件
  if rule.required_files then
    for _, file in ipairs(rule.required_files) do
      local full_path = vim.fn.stdpath("config") .. "/" .. file
      if vim.fn.filereadable(full_path) == 0 then
        table.insert(issues, "缺少必要文件: " .. file)
      end
    end
  end
  
  -- 檢查必要插件
  if rule.required_plugins then
    for _, plugin in ipairs(rule.required_plugins) do
      local plugin_path = vim.fn.stdpath("data") .. "/lazy/" .. plugin:match("([^/]+)$")
      if vim.fn.isdirectory(plugin_path) == 0 then
        table.insert(issues, "缺少必要插件: " .. plugin)
      end
    end
  end
  
  -- 執行自定義檢查函數
  if rule.check_function then
    local success, custom_issues = pcall(rule.check_function)
    if success and custom_issues then
      vim.list_extend(issues, custom_issues)
    elseif not success then
      table.insert(issues, "驗證規則執行失敗: " .. tostring(custom_issues))
    end
  end
  
  return issues
end

-- 主要驗證函數
function M.validate_config()
  local all_issues = {}
  local start_time = vim.loop.hrtime()
  
  error_handler.info("開始配置驗證...")
  
  -- 執行所有驗證規則
  for rule_name, rule in pairs(validation_rules) do
    local issues = validate_rule(rule_name, rule)
    if #issues > 0 then
      all_issues[rule_name] = issues
    end
  end
  
  local end_time = vim.loop.hrtime()
  local duration = (end_time - start_time) / 1000000 -- 轉換為毫秒
  
  -- 報告結果
  if next(all_issues) then
    error_handler.warn("配置驗證發現問題", {
      issues = all_issues,
      duration_ms = duration
    })
    
    -- 詳細輸出到用戶
    print("=== 配置驗證結果 ===")
    for category, issues in pairs(all_issues) do
      print(string.format("⚠️  %s:", category))
      for _, issue in ipairs(issues) do
        print("  • " .. issue)
      end
    end
    print(string.format("驗證完成，耗時: %.2fms", duration))
    
    return false, all_issues
  else
    error_handler.info("配置驗證通過", {
      duration_ms = duration
    })
    return true, {}
  end
end

-- 快速健康檢查
function M.health_check()
  local critical_checks = {
    -- 檢查基本文件存在
    function()
      local files = {
        "init.lua",
        "lua/mappings.lua",
        "lua/options.lua"
      }
      
      for _, file in ipairs(files) do
        local path = vim.fn.stdpath("config") .. "/" .. file
        if vim.fn.filereadable(path) == 0 then
          return false, "缺少核心文件: " .. file
        end
      end
      return true
    end,
    
    -- 檢查 lazy.nvim
    function()
      local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if vim.fn.isdirectory(lazy_path) == 0 then
        return false, "Lazy.nvim 未安裝"
      end
      return true
    end,
    
    -- 檢查 NvChad
    function()
      local success, _ = pcall(require, "nvchad")
      if not success then
        return false, "NvChad 載入失敗"
      end
      return true
    end
  }
  
  for i, check in ipairs(critical_checks) do
    local success, err = check()
    if not success then
      error_handler.critical("健康檢查失敗", {
        check_index = i,
        error = err
      })
      return false
    end
  end
  
  error_handler.info("健康檢查通過")
  return true
end

-- 自動修復功能
function M.auto_fix(issues)
  local fixed = {}
  local failed = {}
  
  if not issues then
    return fixed, failed
  end
  
  -- 嘗試修復已知問題
  for category, category_issues in pairs(issues) do
    for _, issue in ipairs(category_issues) do
      if issue:match("OSC 52 預設啟用") then
        -- 這個需要用戶手動確認，不自動修復
        table.insert(failed, {category = category, issue = issue, reason = "需要用戶確認"})
      elseif issue:match("過多插件設為立即載入") then
        -- 效能問題的修復建議
        table.insert(failed, {category = category, issue = issue, reason = "需要手動檢查插件載入策略"})
      else
        table.insert(failed, {category = category, issue = issue, reason = "未知問題類型"})
      end
    end
  end
  
  return fixed, failed
end

-- 生成診斷報告
function M.generate_report()
  local report = {
    timestamp = os.date("%Y-%m-%d %H:%M:%S"),
    neovim_version = vim.version(),
    config_path = vim.fn.stdpath("config"),
    validation_result = {},
    recommendations = {}
  }
  
  -- 執行驗證
  local success, issues = M.validate_config()
  report.validation_result = {
    success = success,
    issues = issues
  }
  
  -- 生成建議
  if not success then
    report.recommendations = {
      "執行 :lua require('utils.config-validator').auto_fix() 嘗試自動修復",
      "檢查配置文件是否有語法錯誤",
      "考慮更新到最新版本的插件"
    }
  end
  
  -- 輸出報告
  local report_path = vim.fn.stdpath("data") .. "/config_validation_report.json"
  local success, err = pcall(function()
    local file = io.open(report_path, "w")
    if file then
      file:write(vim.json.encode(report))
      file:close()
    end
  end)
  
  if success then
    print("診斷報告已生成: " .. report_path)
  else
    print("生成報告失敗: " .. tostring(err))
  end
  
  return report
end

-- 安裝時自動執行驗證
function M.setup()
  -- 創建自動命令在啟動後執行驗證
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      -- 延遲執行避免影響啟動速度
      vim.defer_fn(function()
        if not M.health_check() then
          error_handler.error("配置健康檢查失敗，請檢查配置")
        end
      end, 1000) -- 1秒後執行
    end,
    once = true
  })
  
  -- 添加用戶命令
  vim.api.nvim_create_user_command("ConfigValidate", function()
    M.validate_config()
  end, { desc = "驗證 NvChad 配置" })
  
  vim.api.nvim_create_user_command("ConfigReport", function()
    M.generate_report()
  end, { desc = "生成配置診斷報告" })
end

return M