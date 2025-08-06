-- Phase 1 向後相容性測試
local test_utils = require('tests.test_utils')

local M = {}

-- 測試舊的 Gemini API 相容性
local function test_gemini_api_compatibility()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 使用舊的 Gemini API
    local gemini_state = { buf = 10, win = 20, job_id = 30 }
    test_utils.assert_true(state.set_gemini_state(gemini_state), "舊的 set_gemini_state 應該有效")
    
    -- 通過舊 API 獲取狀態
    local retrieved = state.get_gemini_state()
    test_utils.assert_not_nil(retrieved, "舊的 get_gemini_state 應該有效") 
    test_utils.assert_equal(retrieved.buf, 10, "通過舊 API 獲取的 buffer 應該正確")
    test_utils.assert_equal(retrieved.win, 20, "通過舊 API 獲取的 window 應該正確")
    test_utils.assert_equal(retrieved.job_id, 30, "通過舊 API 獲取的 job_id 應該正確")
    
    print("✓ Gemini API 相容性測試通過")
end

-- 測試新舊 API 互通性
local function test_new_old_api_interoperability()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 通過新 API 設定 Gemini 狀態
    local new_state = { buf = 100, win = 200, job_id = 300 }
    test_utils.assert_true(state.set_terminal_state("gemini", new_state), "新 API 設定應該成功")
    
    -- 通過舊 API 獲取狀態
    local old_api_retrieved = state.get_gemini_state()
    test_utils.assert_not_nil(old_api_retrieved, "舊 API 應該能獲取新 API 設定的狀態")
    test_utils.assert_equal(old_api_retrieved.buf, 100, "舊 API 獲取的數據應該正確")
    
    -- 通過舊 API 修改狀態
    local modified_state = { buf = 500, win = 600, job_id = 700 }
    test_utils.assert_true(state.set_gemini_state(modified_state), "舊 API 修改應該成功")
    
    -- 通過新 API 獲取修改後的狀態
    local new_api_retrieved = state.get_terminal_state("gemini")
    test_utils.assert_not_nil(new_api_retrieved, "新 API 應該能獲取舊 API 修改的狀態")
    test_utils.assert_equal(new_api_retrieved.buf, 500, "新 API 獲取的數據應該正確")
    
    print("✓ 新舊 API 互通性測試通過")
end

-- 測試 last_active 向後相容性
local function test_last_active_compatibility()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 使用舊的 API 設定最後活躍終端（現在應該對應到 "claude_code"）
    state.set_last_active("claude_code")
    test_utils.assert_equal(state.get_last_active(), "claude_code", "設定最後活躍終端應該有效")
    
    -- 使用新的終端名稱
    state.set_last_active("gemini")
    test_utils.assert_equal(state.get_last_active(), "gemini", "新的終端名稱應該有效")
    
    state.set_last_active("claude")
    test_utils.assert_equal(state.get_last_active(), "claude", "Claude 終端名稱應該有效")
    
    print("✓ Last active 相容性測試通過")
end

-- 測試狀態結構相容性
local function test_state_structure_compatibility()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 設定一個 Gemini 狀態（模擬舊的使用方式）
    local gemini_state = { buf = 1, win = 2, job_id = 3 }
    state.set_gemini_state(gemini_state)
    
    -- 獲取完整狀態
    local full_state = state.get_status()
    
    -- 驗證新的狀態結構存在
    test_utils.assert_not_nil(full_state.terminals, "新的狀態結構應該有 terminals")
    test_utils.assert_not_nil(full_state.global, "新的狀態結構應該有 global")
    
    -- 驗證 Gemini 狀態在新結構中
    test_utils.assert_not_nil(full_state.terminals.gemini, "Gemini 狀態應該在 terminals 中")
    test_utils.assert_equal(full_state.terminals.gemini.buf, 1, "Gemini 的 buffer 應該正確")
    
    print("✓ 狀態結構相容性測試通過")
end

-- 測試清理函數相容性
local function test_cleanup_compatibility()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 設定一些狀態（使用混合的新舊 API）
    state.set_gemini_state({ buf = 1, win = 2, job_id = 3 })
    state.set_terminal_state("claude", { buf = 4, win = 5, job_id = 6 })
    
    -- 測試舊的清理函數仍然有效
    state.cleanup_invalid_state()  -- 這應該不會報錯
    
    -- 驗證狀態仍然存在（因為我們使用的是有效的 ID）
    test_utils.assert_not_nil(state.get_gemini_state(), "清理後 Gemini 狀態應該仍存在")
    test_utils.assert_not_nil(state.get_terminal_state("claude"), "清理後 Claude 狀態應該仍存在")
    
    print("✓ 清理函數相容性測試通過")
end

-- 測試忙碌狀態相容性
local function test_busy_state_compatibility()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 測試忙碌狀態設定（這些函數應該仍然有效）
    test_utils.assert_false(state.is_busy(), "初始應該不忙碌")
    
    state.set_busy(true)
    test_utils.assert_true(state.is_busy(), "設定忙碌後應該為忙碌狀態")
    
    state.set_busy(false)
    test_utils.assert_false(state.is_busy(), "取消忙碌後應該不忙碌")
    
    print("✓ 忙碌狀態相容性測試通過")
end

-- 測試重置函數相容性
local function test_reset_compatibility()
    local state = require('utils.terminal.state')
    
    -- 設定一些狀態
    state.set_gemini_state({ buf = 1, win = 2, job_id = 3 })
    state.set_terminal_state("claude", { buf = 4, win = 5, job_id = 6 })
    state.set_last_active("gemini")
    state.set_busy(true)
    
    -- 執行重置
    state.reset()
    
    -- 驗證所有狀態都被清除
    test_utils.assert_nil(state.get_gemini_state(), "重置後 Gemini 狀態應該被清除")
    test_utils.assert_nil(state.get_terminal_state("claude"), "重置後 Claude 狀態應該被清除")
    test_utils.assert_nil(state.get_last_active(), "重置後最後活躍終端應該被清除")
    test_utils.assert_false(state.is_busy(), "重置後忙碌狀態應該被清除")
    
    local terminals = state.list_terminals()
    test_utils.assert_equal(#terminals, 0, "重置後應該沒有終端")
    
    print("✓ 重置函數相容性測試通過")
end

-- 測試舊代碼中可能的使用模式
local function test_legacy_usage_patterns()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 模擬舊的使用模式 1：直接存取 state.gemini（這在新版本中不應該直接做）
    -- 但是通過 API 應該能正常工作
    state.set_gemini_state({ buf = 10, win = 20, job_id = 30 })
    
    -- 模擬舊的使用模式 2：檢查狀態有效性
    local gemini_state = state.get_gemini_state()
    if gemini_state and gemini_state.buf then
        test_utils.assert_equal(gemini_state.buf, 10, "狀態檢查模式應該有效")
    else
        error("舊的狀態檢查模式失敗")
    end
    
    -- 模擬舊的使用模式 3：清理和重置
    state.cleanup_invalid_state()
    local cleaned_state = state.get_gemini_state()
    test_utils.assert_not_nil(cleaned_state, "清理後狀態應該仍存在")
    
    print("✓ 舊代碼使用模式相容性測試通過")
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
        { name = "gemini_api_compatibility", func = test_gemini_api_compatibility },
        { name = "new_old_api_interoperability", func = test_new_old_api_interoperability },
        { name = "last_active_compatibility", func = test_last_active_compatibility },
        { name = "state_structure_compatibility", func = test_state_structure_compatibility },
        { name = "cleanup_compatibility", func = test_cleanup_compatibility },
        { name = "busy_state_compatibility", func = test_busy_state_compatibility },
        { name = "reset_compatibility", func = test_reset_compatibility },
        { name = "legacy_usage_patterns", func = test_legacy_usage_patterns }
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
    
    print(string.format("\n=== Phase 1 向後相容性測試結果 ==="))
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