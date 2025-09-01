# Architecture Overview

## High-Level Structure
```
dotfiles/
├── install.sh          # Security-hardened installer
├── .vimrc/.tmux.conf   # Traditional editor configs
└── nvim/               # Modern Neovim setup
    ├── init.lua        # NvChad bootstrap
    ├── lua/            # Configuration modules
    │   ├── configs/    # Plugin configurations
    │   ├── plugins/    # Plugin management
    │   └── utils/      # Core utilities
    │       ├── clipboard/  # Modular clipboard system
    │       └── terminal/   # AI terminal management
    ├── tests/          # Comprehensive test suite
    └── docs/           # Complete documentation
```

## Key Architectural Decisions
1. **NvChad Framework**: Uses proven NvChad v2.5 base with minimal customization
2. **Modular Design**: Separate clipboard and terminal systems for maintainability
3. **AI Integration**: Dual-terminal system (Claude Code + Gemini) with smart switching
4. **Version Management**: Locked versions for AI tools, flexible for mature plugins
5. **Security-First**: URL validation, path restrictions, input sanitization
6. **Cross-Platform**: macOS Homebrew optimization, Linux compatibility

## Critical Dependencies
- Neovim 0.9.0+ (auto-installed)
- Node.js 16.0+ (GitHub Copilot)
- ripgrep (search functionality)
- Nerd Fonts (icon display)