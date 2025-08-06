-- Phase 1 狀態管理核心測試
local test_utils = require('tests.test_utils')

local M = {}

-- 測試多終端狀態設定和獲取
local function test_multi_terminal_state()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 測試設定多個終端狀態
    local gemini_state = { buf = 1, win = 2, job_id = 3 }
    local claude_state = { buf = 4, win = 5, job_id = 6 }
    
    test_utils.assert_true(state.set_terminal_state("gemini", gemini_state), "應該能設定 Gemini 狀態")
    test_utils.assert_true(state.set_terminal_state("claude", claude_state), "應該能設定 Claude 狀態")
    
    -- 測試獲取狀態
    local retrieved_gemini = state.get_terminal_state("gemini")
    local retrieved_claude = state.get_terminal_state("claude")
    
    test_utils.assert_not_nil(retrieved_gemini, "應該能獲取 Gemini 狀態")
    test_utils.assert_not_nil(retrieved_claude, "應該能獲取 Claude 狀態")
    
    test_utils.assert_equal(retrieved_gemini.buf, 1, "Gemini buffer 應該正確")
    test_utils.assert_equal(retrieved_claude.buf, 4, "Claude buffer 應該正確")
    
    print("✓ 多終端狀態設定和獲取測試通過")
end

-- 測試狀態隔離
local function test_state_isolation()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 設定不同的終端狀態
    state.set_terminal_state("gemini", { buf = 10, win = 20, job_id = 30 })
    state.set_terminal_state("claude", { buf = 11, win = 21, job_id = 31 })
    
    -- 驗證狀態隔離
    local is_isolated, message = state.validate_state_isolation()
    test_utils.assert_true(is_isolated, "狀態應該正確隔離: " .. (message or ""))
    
    -- 修改一個終端狀態，不應影響另一個
    state.set_terminal_state("gemini", { buf = 100 })
    
    local gemini_state = state.get_terminal_state("gemini")
    local claude_state = state.get_terminal_state("claude")
    
    test_utils.assert_equal(gemini_state.buf, 100, "Gemini 狀態應該已更新")
    test_utils.assert_equal(claude_state.buf, 11, "Claude 狀態不應受影響")
    
    print("✓ 狀態隔離測試通過")
end

-- 測試終端列表功能
local function test_terminal_listing()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 初始應該沒有終端
    local terminals = state.list_terminals()
    test_utils.assert_equal(#terminals, 0, "初始應該沒有終端")
    
    -- 添加終端
    state.set_terminal_state("gemini", { buf = 1 })
    state.set_terminal_state("claude", { buf = 2 })
    state.set_terminal_state("test", { buf = 3 })
    
    -- 檢查列表
    terminals = state.list_terminals()
    test_utils.assert_equal(#terminals, 3, "應該有 3 個終端")
    
    -- 檢查是否包含所有終端
    local terminal_set = {}
    for _, name in ipairs(terminals) do
        terminal_set[name] = true
    end
    
    test_utils.assert_true(terminal_set["gemini"], "應該包含 gemini")
    test_utils.assert_true(terminal_set["claude"], "應該包含 claude")
    test_utils.assert_true(terminal_set["test"], "應該包含 test")
    
    print("✓ 終端列表功能測試通過")
end

-- 測試最後活躍終端追蹤
local function test_last_active_tracking()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 初始應該沒有最後活躍終端
    test_utils.assert_nil(state.get_last_active(), "初始應該沒有最後活躍終端")
    
    -- 設定最後活躍終端
    state.set_last_active("gemini")
    test_utils.assert_equal(state.get_last_active(), "gemini", "最後活躍終端應該是 gemini")
    
    state.set_last_active("claude")
    test_utils.assert_equal(state.get_last_active(), "claude", "最後活躍終端應該是 claude")
    
    print("✓ 最後活躍終端追蹤測試通過")
end

-- 測試狀態清理功能
local function test_state_cleanup()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 設定一些終端狀態
    state.set_terminal_state("gemini", { buf = 1, win = 2, job_id = 3 })
    state.set_terminal_state("claude", { buf = 4, win = 5, job_id = 6 })
    
    -- 驗證狀態存在
    test_utils.assert_not_nil(state.get_terminal_state("gemini"), "Gemini 狀態應該存在")
    test_utils.assert_not_nil(state.get_terminal_state("claude"), "Claude 狀態應該存在")
    
    -- 移除一個終端狀態
    test_utils.assert_true(state.remove_terminal_state("gemini"), "應該能移除 Gemini 狀態")
    
    -- 驗證狀態已移除
    test_utils.assert_nil(state.get_terminal_state("gemini"), "Gemini 狀態應該已移除")
    test_utils.assert_not_nil(state.get_terminal_state("claude"), "Claude 狀態應該仍存在")
    
    print("✓ 狀態清理功能測試通過")
end

-- 測試向後相容性
local function test_backward_compatibility()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 測試舊的 Gemini API
    local gemini_state = { buf = 10, win = 20, job_id = 30 }
    test_utils.assert_true(state.set_gemini_state(gemini_state), "舊的 set_gemini_state 應該有效")
    
    local retrieved = state.get_gemini_state()
    test_utils.assert_not_nil(retrieved, "舊的 get_gemini_state 應該有效")
    test_utils.assert_equal(retrieved.buf, 10, "通過舊 API 設定的狀態應該正確")
    
    -- 驗證新 API 也能存取相同狀態
    local new_api_retrieved = state.get_terminal_state("gemini")
    test_utils.assert_equal(new_api_retrieved.buf, 10, "新 API 應該能存取舊 API 設定的狀態")
    
    print("✓ 向後相容性測試通過")
end

-- 運行所有測試
function M.run_all()
    local results = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    local tests = {
        { name = "multi_terminal_state", func = test_multi_terminal_state },
        { name = "state_isolation", func = test_state_isolation },
        { name = "terminal_listing", func = test_terminal_listing },
        { name = "last_active_tracking", func = test_last_active_tracking },
        { name = "state_cleanup", func = test_state_cleanup },
        { name = "backward_compatibility", func = test_backward_compatibility }
    }
    
    for _, test in ipairs(tests) do
        results.total = results.total + 1
        
        local success, err = pcall(test.func)
        if success then
            results.passed = results.passed + 1
            print(string.format("✓ %s 通過", test.name))
        else
            results.failed = results.failed + 1
            results.errors[test.name] = err
            print(string.format("✗ %s 失敗: %s", test.name, tostring(err)))
        end
    end
    
    print(string.format("\n=== Phase 1 狀態管理測試結果 ==="))
    print(string.format("總測試數: %d", results.total))
    print(string.format("通過: %d", results.passed))
    print(string.format("失敗: %d", results.failed))
    print(string.format("成功率: %.1f%%", results.total > 0 and (results.passed / results.total * 100) or 0))
    
    return results
end

-- 如果作為腳本直接運行，執行測試
if not pcall(debug.getlocal, 4, 1) then
    M.run_all()
end

return M