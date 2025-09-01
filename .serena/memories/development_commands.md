# Development Commands

## Installation Commands
```bash
./install.sh                    # Full installation with backups
./install.sh --vim              # Vim only
./install.sh --tmux             # Tmux only  
./install.sh --nvim             # Neovim only
./install.sh --install-deps     # Install dependencies
./install.sh --check-only       # Status check without installation
```

## Testing Commands
```bash
cd nvim && ./scripts/run_tests.sh              # Run full test suite
./scripts/run_tests.sh --health-check          # Health check mode
nvim +checkhealth +qa                          # Neovim health check
nvim -c "luafile tests/test_runner.lua"        # Alternative test runner
```

## Maintenance Commands
```bash
# Vim
vim +PlugInstall +qall          # Install vim plugins
vim +PlugUpdate +qall           # Update vim plugins

# Tmux  
tmux source-file ~/.tmux.conf   # Reload tmux config

# Neovim
nvim +Lazy                      # Open plugin manager
rm -rf ~/.local/share/nvim ~/.cache/nvim  # Clear nvim cache
```

## Security & Quality Assurance
```bash
nvim --headless -c "luafile nvim/tests/terminal/penetration_test.lua" -c "qa"  # Security test
tail -f ~/.local/share/nvim/log # Monitor nvim logs
```