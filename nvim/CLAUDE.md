# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Neovim Configuration Overview

This is a personal Neovim configuration based on the NvChad framework (v2.5). The configuration leverages NvChad's robust foundation while adding custom plugins and workflows optimized for AI-assisted development and modern software engineering practices.

## File Structure

```
~/.config/nvim/           # NvChat configuration (actual location)
├── LICENSE
├── README.md             # NvChad usage instructions
├── init.lua              # NvChad bootstrap entry point
├── lazy-lock.json        # Plugin version lockfile
└── lua/
    ├── autocmds.lua      # Auto commands and event handlers
    ├── chadrc.lua        # NvChad theme and UI configuration
    ├── mappings.lua      # Custom key mappings with AI integration
    ├── options.lua       # Neovim settings and options
    ├── configs/          # Configuration modules
    │   ├── conform.lua   # Code formatting configuration
    │   ├── lazy.lua      # Lazy.nvim setup for NvChad
    │   └── lspconfig.lua # Language Server Protocol setup
    ├── plugins/          # Custom plugin additions
    │   └── init.lua      # Claude Code and auto-session plugins
    └── utils/            # Utility modules
        └── clipboard.lua # Advanced clipboard management for AI workflows
```

## Development Commands

### Plugin Management
- **Install/Update plugins**: Launch nvim - NvChad will auto-install missing plugins
- **Plugin status**: `:Lazy` - Opens lazy.nvim interface
- **Plugin updates**: `:Lazy update` - Updates all plugins
- **Plugin sync**: `:Lazy sync` - Syncs lockfile with current plugin state
- **NvChad updates**: Follow NvChad documentation for framework updates

### Configuration Testing
- **Reload config**: Restart nvim or use `:source %` in config files
- **Check health**: `:checkhealth` - Diagnoses configuration issues
- **Plugin health**: `:checkhealth lazy` - Checks plugin manager status
- **NvChad health**: `:checkhealth nvchad` - Checks framework status

### Theme Management
- **Theme switching**: Use NvChad's built-in theme picker
- **Theme customization**: Modify `chadrc.lua` for theme settings

## Key Architecture Details

### NvChad Framework Integration
- **Base Framework**: Built on NvChad v2.5 with proven defaults and optimizations
- **Plugin Ecosystem**: Inherits NvChad's curated plugin selection
- **Theme System**: Uses NvChad's base46 theme system with dynamic switching
- **Performance**: Framework-level optimizations and lazy loading

### Configuration Structure
- **Framework-based**: Builds upon NvChad's solid foundation
- **Minimal Custom Plugins**: Only essential additions (Claude Code, auto-session)
- **Leader key**: Space (`<leader>`) for custom mappings
- **Smart Defaults**: NvChad handles most configuration automatically

### Key Components
- **NvChad Dashboard**: Built-in startup screen with project actions
- **Telescope**: Fuzzy finder integration (NvChad configured)
- **Nvim-tree**: File explorer with NvChad theming
- **Claude Code**: Custom AI-assisted development integration
- **Advanced Clipboard**: Sophisticated clipboard management for AI workflows
- **Auto-session**: Session management with project state persistence
- **LSP Integration**: Pre-configured language servers via NvChad
- **Base46 Themes**: Dynamic theme switching with multiple built-in options

### Key Bindings Philosophy
- **Leader key** (`<space>`): Primary namespace for custom commands
- **NvChad Defaults**: Inherits NvChad's proven keybinding conventions
- **AI Integration**: Custom bindings for Claude Code workflows
  - `<leader>cpr`: Create file path reference for AI context
  - `<leader>cpp`: Process and compress clipboard content
- **Advanced Clipboard**: Smart clipboard operations for development workflows
- **Framework Bindings**: Standard NvChad navigation and editing shortcuts

### Settings Notable Points
- **NvChad Defaults**: Inherits framework's optimized settings
- **Line numbers**: Relative numbering enabled
- **Search**: Case-smart search behavior with NvChad enhancements
- **Clipboard**: Advanced system clipboard integration with AI utilities
- **Sessions**: Auto-session support for seamless project switching
- **LSP**: Pre-configured language servers with intelligent defaults
- **Performance**: Framework-level optimizations for large codebases

## AI-Assisted Development Features

### Advanced Clipboard Management
The configuration includes sophisticated clipboard utilities optimized for AI workflows:

- **File Path References**: `<leader>cpr` creates formatted file references for AI context
- **Content Compression**: `<leader>cpp` processes and compresses clipboard content
- **Smart Detection**: Automatically handles different content types and formats
- **AI Integration**: Seamless integration with Claude Code for enhanced productivity

### Custom Plugin Integration

When adding new plugins to the NvChad setup:
1. Add plugin specs to `lua/plugins/init.lua`
2. Follow NvChad's plugin configuration patterns
3. Respect framework conventions and theming
4. Test compatibility with NvChad's plugin ecosystem
5. Verify theme integration with base46 system

When modifying the configuration:
1. Understand NvChad's architecture before making changes
2. Use `chadrc.lua` for theme and UI customizations
3. Add custom mappings to `mappings.lua`
4. Maintain compatibility with framework updates
5. Document any deviations from NvChad conventions

## Commit Message Guidelines

### Recommended Practices
- Avoid automatically generated text in commit messages
- Do not include generic co-authored or generated text
- Focus on clear, concise commit message descriptions that explain the specific changes

## Dotfiles Synchronization

- 直接複製 dotfiles 中的完整配置，確保每次同步後的install能反應最新的狀況