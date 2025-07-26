# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing configuration files for vim, tmux, and neovim. The repository includes an automated installation script and comprehensive configurations optimized for development productivity.

## File Structure

```
.
├── .vimrc              # Vim configuration with vim-plug and AI plugins
├── .tmux.conf          # Tmux configuration with Ctrl-a prefix
├── nvim/               # Neovim configuration (NvChad-based)
│   ├── init.lua        # NvChad bootstrap entry point
│   ├── lazy-lock.json  # Plugin version lockfile
│   └── lua/            # Configuration modules
├── install.sh          # Automated installation script
└── README.md           # User documentation
```

## Development Commands

### Installation and Setup
- **Full installation**: `./install.sh` - Installs all configurations with backups
- **Selective installation**: 
  - `./install.sh --vim` - Install only vim configuration
  - `./install.sh --tmux` - Install only tmux configuration  
  - `./install.sh --nvim` - Install only neovim configuration

### Testing Configuration Changes
- **Vim**: Open vim and run `:PlugInstall` after configuration changes
- **Tmux**: `tmux source-file ~/.tmux.conf` to reload configuration
- **Neovim**: Restart nvim - lazy.nvim will auto-install/update plugins

### Maintenance Commands
- **Vim plugin updates**: `:PlugUpdate` in vim
- **Neovim plugin management**: `:Lazy` interface for plugin operations
- **Clear neovim cache**: `rm -rf ~/.local/share/nvim ~/.cache/nvim`

## Architecture Details

### Installation Script (`install.sh`)
- **Security-focused**: Checks script permissions and validates inputs
- **Backup system**: Automatically backs up existing configurations
- **Cross-platform**: Supports macOS and Linux environments
- **Error handling**: Comprehensive logging and error recovery

### Vim Configuration (`.vimrc`)
- **Plugin manager**: vim-plug with lazy loading optimizations
- **Key plugins**: ALE, fzf, vim-gitgutter, lightline, Codeium, Claude.vim
- **Leader key**: `,` (comma)
- **Security**: Disabled unsafe features and modelines

### Tmux Configuration (`.tmux.conf`)
- **Prefix key**: `Ctrl-a` (replaces default `Ctrl-b`)
- **Vi mode**: Enabled for copy/paste operations
- **Mouse support**: Full mouse integration
- **Default shell**: bash

### Neovim Configuration (`nvim/`)
- **Framework**: Based on NvChad v2.5 with proven defaults
- **Plugin manager**: lazy.nvim with optimized loading
- **Leader key**: Space for custom mappings
- **AI integration**: Claude Code plugin with advanced clipboard utilities
- **Session management**: Auto-session for project state persistence

## Development Guidelines

### When modifying configurations:
1. Always test changes in isolation before committing
2. Update the install script if new dependencies are required
3. Maintain cross-platform compatibility (macOS/Linux)
4. Follow existing code style and conventions
5. Update backup and restore functionality if needed

### When working with Neovim:
1. Respect NvChad's architecture and conventions
2. Add custom plugins to `lua/plugins/init.lua`
3. Use `chadrc.lua` for theme and UI customizations
4. Test compatibility with NvChad's plugin ecosystem

### File permissions and security:
- Install script should maintain 755 permissions
- Configuration files should be readable but not executable
- Never commit sensitive information or API keys

## Commit Message Guidelines

- Use descriptive commit messages in Chinese (traditional/simplified)
- Focus on the specific change rather than generic descriptions
- Standard format: `修正/新增/更新 [component] [description]`

## NvChad Best Practices

- 當使用框架如 NvChad 時，最好：
  1. 先使用框架的默認配置
  2. 只在必要時進行最小化的自定義
  3. 避免覆蓋複雜的嵌套配置結構
  4. 測試每個修改的影響