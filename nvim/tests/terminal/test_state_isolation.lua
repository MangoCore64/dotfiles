-- Phase 1 狀態隔離專項測試
local test_utils = require('tests.test_utils')

local M = {}

-- 測試基本狀態隔離
local function test_basic_state_isolation()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 設定兩個不同的終端
    state.set_terminal_state("terminal1", { buf = 1, win = 10, job_id = 100 })
    state.set_terminal_state("terminal2", { buf = 2, win = 20, job_id = 200 })
    
    -- 驗證狀態隔離
    local is_isolated, message = state.validate_state_isolation()
    test_utils.assert_true(is_isolated, "基本狀態隔離應該通過: " .. (message or ""))
    
    -- 驗證各終端狀態獨立
    local t1_state = state.get_terminal_state("terminal1")
    local t2_state = state.get_terminal_state("terminal2")
    
    test_utils.assert_not_equal(t1_state.buf, t2_state.buf, "不同終端的 buffer 應該不同")
    test_utils.assert_not_equal(t1_state.win, t2_state.win, "不同終端的 window 應該不同")
    test_utils.assert_not_equal(t1_state.job_id, t2_state.job_id, "不同終端的 job_id 應該不同")
    
    print("✓ 基本狀態隔離測試通過")
end

-- 測試狀態洩露檢測
local function test_state_leak_detection()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 故意創建共享 buffer 的狀態（模擬狀態洩露）
    state.set_terminal_state("terminal1", { buf = 100, win = 10, job_id = 1000 })
    state.set_terminal_state("terminal2", { buf = 100, win = 20, job_id = 2000 })  -- 相同的 buf
    
    -- 檢測應該失敗
    local is_isolated, message = state.validate_state_isolation()
    test_utils.assert_false(is_isolated, "應該檢測到 buffer 共享")
    test_utils.assert_true(message:find("共享相同的 buffer"), "錯誤訊息應該指出 buffer 共享")
    
    print("✓ 狀態洩露檢測測試通過")
end

-- 測試 window 共享檢測
local function test_window_sharing_detection()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 故意創建共享 window 的狀態
    state.set_terminal_state("terminal1", { buf = 10, win = 100, job_id = 1000 })
    state.set_terminal_state("terminal2", { buf = 20, win = 100, job_id = 2000 })  -- 相同的 win
    
    -- 檢測應該失敗
    local is_isolated, message = state.validate_state_isolation()
    test_utils.assert_false(is_isolated, "應該檢測到 window 共享")
    test_utils.assert_true(message:find("共享相同的 window"), "錯誤訊息應該指出 window 共享")
    
    print("✓ Window 共享檢測測試通過")
end

-- 測試狀態修改隔離
local function test_state_modification_isolation()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 設定初始狀態
    state.set_terminal_state("terminal1", { buf = 1, win = 10, job_id = 100 })
    state.set_terminal_state("terminal2", { buf = 2, win = 20, job_id = 200 })
    
    -- 記錄初始狀態
    local initial_t2 = vim.tbl_deep_extend("force", {}, state.get_terminal_state("terminal2"))
    
    -- 修改 terminal1 的狀態
    state.set_terminal_state("terminal1", { buf = 999, win = 888, job_id = 777 })
    
    -- 驗證 terminal2 狀態未受影響
    local final_t2 = state.get_terminal_state("terminal2")
    
    test_utils.assert_equal(initial_t2.buf, final_t2.buf, "terminal2 的 buffer 不應受影響")
    test_utils.assert_equal(initial_t2.win, final_t2.win, "terminal2 的 window 不應受影響")
    test_utils.assert_equal(initial_t2.job_id, final_t2.job_id, "terminal2 的 job_id 不應受影響")
    
    -- 驗證 terminal1 狀態正確更新
    local final_t1 = state.get_terminal_state("terminal1")
    test_utils.assert_equal(final_t1.buf, 999, "terminal1 的 buffer 應該已更新")
    
    print("✓ 狀態修改隔離測試通過")
end

-- 測試並發操作隔離
local function test_concurrent_operation_isolation()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 模擬並發設定操作
    state.set_terminal_state("terminal1", { buf = 1 })
    state.set_terminal_state("terminal2", { buf = 2 })
    state.set_terminal_state("terminal3", { buf = 3 })
    
    -- 同時修改多個終端
    state.set_terminal_state("terminal1", { buf = 11, win = 110 })
    state.set_terminal_state("terminal2", { buf = 22, win = 220 })
    state.set_terminal_state("terminal3", { buf = 33, win = 330 })
    
    -- 驗證每個終端都有正確的狀態
    local t1 = state.get_terminal_state("terminal1")
    local t2 = state.get_terminal_state("terminal2")
    local t3 = state.get_terminal_state("terminal3")
    
    test_utils.assert_equal(t1.buf, 11, "terminal1 應該有正確的 buffer")
    test_utils.assert_equal(t2.buf, 22, "terminal2 應該有正確的 buffer")
    test_utils.assert_equal(t3.buf, 33, "terminal3 應該有正確的 buffer")
    
    test_utils.assert_equal(t1.win, 110, "terminal1 應該有正確的 window")
    test_utils.assert_equal(t2.win, 220, "terminal2 應該有正確的 window")
    test_utils.assert_equal(t3.win, 330, "terminal3 應該有正確的 window")
    
    -- 驗證狀態隔離仍然正常
    local is_isolated, message = state.validate_state_isolation()
    test_utils.assert_true(is_isolated, "並發操作後狀態隔離應該正常: " .. (message or ""))
    
    print("✓ 並發操作隔離測試通過")
end

-- 測試清理操作的隔離性
local function test_cleanup_isolation()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 設定多個終端
    state.set_terminal_state("terminal1", { buf = 1, win = 10, job_id = 100 })
    state.set_terminal_state("terminal2", { buf = 2, win = 20, job_id = 200 })
    state.set_terminal_state("terminal3", { buf = 3, win = 30, job_id = 300 })
    
    -- 移除其中一個終端
    test_utils.assert_true(state.remove_terminal_state("terminal2"), "應該能移除 terminal2")
    
    -- 驗證其他終端狀態未受影響
    local t1 = state.get_terminal_state("terminal1")
    local t3 = state.get_terminal_state("terminal3")
    
    test_utils.assert_not_nil(t1, "terminal1 應該仍然存在")
    test_utils.assert_not_nil(t3, "terminal3 應該仍然存在")
    test_utils.assert_nil(state.get_terminal_state("terminal2"), "terminal2 應該已被移除")
    
    test_utils.assert_equal(t1.buf, 1, "terminal1 狀態應該完整")
    test_utils.assert_equal(t3.buf, 3, "terminal3 狀態應該完整")
    
    print("✓ 清理操作隔離測試通過")
end

-- 測試多終端的時間戳隔離
local function test_timestamp_isolation()
    local state = require('utils.terminal.state')
    
    -- 清理初始狀態
    state.reset()
    
    -- 分別設定終端（模擬不同時間）
    state.set_terminal_state("terminal1", { buf = 1 })
    local t1_time = state.get_terminal_state("terminal1").last_active
    
    -- 等待一點時間（在測試環境中可能很短）
    vim.wait(10)
    
    state.set_terminal_state("terminal2", { buf = 2 })
    local t2_time = state.get_terminal_state("terminal2").last_active
    
    -- 驗證時間戳不同（或至少不會相互影響）
    test_utils.assert_not_nil(t1_time, "terminal1 應該有時間戳")
    test_utils.assert_not_nil(t2_time, "terminal2 應該有時間戳")
    
    -- 更新 terminal1，不應影響 terminal2 的時間戳
    local original_t2_time = t2_time
    state.set_terminal_state("terminal1", { buf = 11 })
    
    local updated_t2_time = state.get_terminal_state("terminal2").last_active
    test_utils.assert_equal(original_t2_time, updated_t2_time, "terminal2 的時間戳不應受 terminal1 更新影響")
    
    print("✓ 時間戳隔離測試通過")
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
        { name = "basic_state_isolation", func = test_basic_state_isolation },
        { name = "state_leak_detection", func = test_state_leak_detection },
        { name = "window_sharing_detection", func = test_window_sharing_detection },
        { name = "state_modification_isolation", func = test_state_modification_isolation },
        { name = "concurrent_operation_isolation", func = test_concurrent_operation_isolation },
        { name = "cleanup_isolation", func = test_cleanup_isolation },
        { name = "timestamp_isolation", func = test_timestamp_isolation }
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
    
    print(string.format("\n=== Phase 1 狀態隔離測試結果 ==="))
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