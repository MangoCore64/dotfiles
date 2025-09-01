#!/bin/bash

# Simplified Neovim Configuration Test Runner
# Follows Linus principle: "Do one thing well"

echo "=== Simplified Neovim Config Test Runner ==="
echo "Focus: Clipboard functionality and configuration health"
echo

CONFIG_DIR="$HOME/.config/nvim"

# Ensure we're in the correct directory
cd "$CONFIG_DIR"

# Pre-flight checks
echo "Pre-flight checks:"
echo "- Neovim version: $(nvim --version | head -1)"
echo "- Config directory: $CONFIG_DIR"
echo "- Clipboard module exists: $([ -f lua/utils/clipboard.lua ] && echo 'Yes' || echo 'No')"
echo

# Health check function
health_check() {
    echo "=== Configuration Health Check ==="
    nvim --headless -c "
        lua local test_runner = require('tests.test_runner')
        local success = test_runner.health_check()
        vim.cmd('qa')
    "
    echo
}

# Run clipboard tests
clipboard_tests() {
    echo "=== Clipboard Functionality Tests ==="
    nvim --headless -c "
        lua local test_runner = require('tests.test_runner')
        local success = test_runner.run_clipboard_tests()
        if success then
            print('✓ All clipboard tests passed')
        else
            print('✗ Some clipboard tests failed')
        end
        vim.cmd('qa')
    "
    echo
}

# Run all tests
run_all() {
    echo "=== Running All Available Tests ==="
    health_check
    clipboard_tests
    echo "Test run completed."
}

# Parse command line arguments
case "${1:-all}" in
    "health"|"--health")
        health_check
        ;;
    "clipboard"|"--clipboard")
        clipboard_tests
        ;;
    "all"|"--all"|"")
        run_all
        ;;
    "help"|"--help")
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  health      - Run configuration health check"
        echo "  clipboard   - Run clipboard functionality tests" 
        echo "  all         - Run all available tests (default)"
        echo "  help        - Show this help message"
        echo
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage information."
        exit 1
        ;;
esac