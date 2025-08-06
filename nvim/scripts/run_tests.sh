#!/bin/bash

# Clipboard.lua 測試運行腳本
echo "=== Clipboard.lua Test Runner ==="
echo "Using plenary.nvim-based testing framework"
echo

CONFIG_DIR="$HOME/.config/nvim"

# 確保在正確的目錄
cd "$CONFIG_DIR"

# 運行測試前檢查
echo "Pre-flight checks:"
echo "- Neovim version: $(nvim --version | head -1)"
echo "- Config directory: $CONFIG_DIR"
echo "- Clipboard backup exists: $([ -f lua/utils/clipboard.lua.backup ] && echo 'Yes' || echo 'No')"
echo

# 運行特定測試
run_test() {
    local test_name="$1"
    echo "Running test: $test_name"
    nvim --headless -c "
        lua package.path = package.path .. ';' .. vim.fn.stdpath('config') .. '/?.lua'
        local test_runner = require('tests.test_runner')
        local success, result = pcall(test_runner.run_test, '$test_name')
        if success then
            print('Test completed successfully')
            if result.errors and #result.errors > 0 then
                print('Errors found:')
                for name, error in pairs(result.errors) do
                    print('  ' .. name .. ': ' .. tostring(error))
                end
                vim.cmd('cquit 1')
            else
                vim.cmd('quit')
            end
        else
            print('Test runner failed: ' .. tostring(result))
            vim.cmd('cquit 1')
        end
    "
    
    if [ $? -eq 0 ]; then
        echo "✓ $test_name passed"
        return 0
    else
        echo "✗ $test_name failed"
        return 1
    fi
}

# 運行所有測試
run_all_tests() {
    echo "Running all tests..."
    nvim --headless -c "
        lua package.path = package.path .. ';' .. vim.fn.stdpath('config') .. '/?.lua'
        local test_runner = require('tests.test_runner')
        local results = test_runner.run_all()
        
        -- 計算總體結果
        local total_passed = 0
        local total_tests = 0
        local has_errors = false
        
        for test_file, result in pairs(results) do
            total_tests = total_tests + (result.total or 0)
            total_passed = total_passed + (result.passed or 0)
            if result.errors and next(result.errors) then
                has_errors = true
            end
        end
        
        if has_errors or total_passed < total_tests then
            vim.cmd('cquit 1')
        else
            vim.cmd('quit')
        end
    "
    
    return $?
}

# 驗證 Phase 0 修復
verify_phase0() {
    echo "=== Phase 0 Verification ==="
    echo "Running terminal security and backup tests..."
    nvim --headless -c "
        lua package.path = package.path .. ';' .. vim.fn.stdpath('config') .. '/?.lua'
        local test_runner = require('tests.test_runner')
        local results = test_runner.run_terminal_category('phase0')
        
        -- 計算總體結果
        local total_passed = 0
        local total_tests = 0
        local has_errors = false
        
        for test_file, result in pairs(results) do
            total_tests = total_tests + (result.total or 0)
            total_passed = total_passed + (result.passed or 0)
            if result.errors and next(result.errors) then
                has_errors = true
            end
        end
        
        if has_errors or total_passed < total_tests then
            vim.cmd('cquit 1')
        else
            vim.cmd('quit')
        end
    "
    
    local result=$?
    if [ $result -eq 0 ]; then
        echo "✅ Phase 0 終端安全修復驗證通過"
    else
        echo "❌ Phase 0 終端安全修復驗證失敗"
    fi
    
    return $result
}

# 驗證 Phase 1 狀態管理重構
verify_phase1() {
    echo "=== Phase 1 Verification ==="
    echo "Running state management and compatibility tests..."
    nvim --headless -c "
        lua package.path = package.path .. ';' .. vim.fn.stdpath('config') .. '/?.lua'
        local test_runner = require('tests.test_runner')
        local results = test_runner.run_terminal_category('phase1')
        
        -- 計算總體結果
        local total_passed = 0
        local total_tests = 0
        local has_errors = false
        
        for test_file, result in pairs(results) do
            total_tests = total_tests + (result.total or 0)
            total_passed = total_passed + (result.passed or 0)
            if result.errors and next(result.errors) then
                has_errors = true
            end
        end
        
        if has_errors or total_passed < total_tests then
            vim.cmd('cquit 1')
        else
            vim.cmd('quit')
        end
    "
    
    local result=$?
    if [ $result -eq 0 ]; then
        echo "✅ Phase 1 狀態管理重構驗證通過"
    else
        echo "❌ Phase 1 狀態管理重構驗證失敗"
    fi
    
    return $result
}

# 通用階段測試函數
run_phase_tests() {
    local phase="$1"
    local description="$2"
    
    echo "=== $description ==="
    echo "Running $phase tests..."
    nvim --headless -c "
        lua package.path = package.path .. ';' .. vim.fn.stdpath('config') .. '/?.lua'
        local test_runner = require('tests.test_runner')
        local results = test_runner.run_terminal_category('$phase')
        
        -- 計算總體結果
        local total_passed = 0
        local total_tests = 0
        local has_errors = false
        
        for test_file, result in pairs(results) do
            total_tests = total_tests + (result.total or 0)
            total_passed = total_passed + (result.passed or 0)
            if result.errors and next(result.errors) then
                has_errors = true
            end
        end
        
        if has_errors or total_passed < total_tests then
            vim.cmd('cquit 1')
        else
            vim.cmd('quit')
        end
    "
    
    local result=$?
    if [ $result -eq 0 ]; then
        echo "✅ $description 驗證通過"
    else
        echo "❌ $description 驗證失敗"
    fi
    
    return $result
}

# 主函數
main() {
    case "${1:-all}" in
        "critical")
            run_test "test_critical_fixes"
            ;;
        "security")
            run_test "test_security"
            ;;
        "performance")
            run_test "test_performance"
            ;;
        "compatibility")
            run_test "test_api_compatibility"
            ;;
        "phase0")
            verify_phase0
            ;;
        "phase1")
            verify_phase1
            ;;
        "phase2")
            run_phase_tests "phase2" "Phase 2: 安全核心模組建立"
            ;;
        "phase3")
            run_phase_tests "phase3" "Phase 3: Gemini 適配器重構"
            ;;
        "phase4")
            run_phase_tests "phase4" "Phase 4: Claude 適配器重構"
            ;;
        "phase5")
            run_phase_tests "phase5" "Phase 5: 終端管理器整合"
            ;;
        "phase6")
            run_phase_tests "phase6" "Phase 6: 監控與文檔完善"
            ;;
        "final")
            run_phase_tests "final" "最終整合測試"
            ;;
        "all")
            run_all_tests
            ;;
        *)
            echo "Usage: $0 [critical|security|performance|compatibility|phase0|phase1|phase2|phase3|phase4|phase5|phase6|final|all]"
            echo "  critical     - Run critical issues tests"
            echo "  security     - Run security tests"
            echo "  performance  - Run performance tests"  
            echo "  compatibility- Run API compatibility tests"
            echo "  phase0       - Verify Phase 0 terminal security fixes"
            echo "  phase1       - Verify Phase 1 state management"
            echo "  phase2       - Verify Phase 2 core modules"
            echo "  phase3       - Verify Phase 3 Gemini adapter"
            echo "  phase4       - Verify Phase 4 Claude adapter"
            echo "  phase5       - Verify Phase 5 manager integration"
            echo "  phase6       - Verify Phase 6 monitoring"
            echo "  final        - Run complete integration tests"
            echo "  all          - Run all tests (default)"
            exit 1
            ;;
    esac
}

main "$@"