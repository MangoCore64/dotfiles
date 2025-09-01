# Dotfiles Project Analysis

## Project Purpose
Personal dotfiles repository for vim, tmux, and neovim configurations with automated installation and AI integration.

## Tech Stack
- **Languages**: Bash (install script), Lua (Neovim config), Vim script
- **Frameworks**: NvChad v2.5 for Neovim
- **Package Managers**: vim-plug (Vim), lazy.nvim (Neovim)
- **AI Integration**: Claude Code, GitHub Copilot, Gemini AI

## Key Components
1. **Install Script** (`install.sh`): Automated, security-focused installer with cross-platform support
2. **Vim Config** (`.vimrc`): Traditional vim setup with modern plugins
3. **Tmux Config** (`.tmux.conf`): Terminal multiplexer with Ctrl-a prefix
4. **Neovim Config** (`nvim/`): Modern NvChad-based setup with AI integration

## Architecture Highlights
- Modular design with separate clipboard/ and terminal/ utilities
- Comprehensive testing system (32+ test files)
- Security-first approach with URL validation and path restrictions
- Cross-platform support (macOS/Linux) with platform-specific optimizations