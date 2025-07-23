# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Neovim Configuration Overview

This is a personal Neovim configuration using Lua and the lazy.nvim plugin manager. The configuration is designed for modern Neovim development with a focus on productivity and clean UI.

## File Structure

```
├── init.lua              # Main entry point - loads all config modules
├── lazy-lock.json        # Plugin version lockfile
├── coc-settings.json     # COC plugin settings (if used)
└── lua/
    ├── config/           # Core configuration modules
    │   ├── init.lua      # Basic Neovim options and settings
    │   ├── keymaps.lua   # Key mappings and shortcuts
    │   ├── lazy.lua      # Lazy.nvim plugin manager setup
    │   └── options.lua   # Additional Neovim options
    └── plugins/          # Individual plugin configurations
        ├── alpha.lua     # Dashboard/startup screen
        ├── telescope.lua # Fuzzy finder
        ├── nvim-tree.lua # File explorer
        ├── claude-code.lua # Claude Code integration
        └── [others...]   # Various UI and utility plugins
```

## Development Commands

### Plugin Management
- **Install/Update plugins**: Launch nvim - lazy.nvim will auto-install missing plugins
- **Plugin status**: `:Lazy` - Opens lazy.nvim interface
- **Plugin updates**: `:Lazy update` - Updates all plugins
- **Plugin sync**: `:Lazy sync` - Syncs lockfile with current plugin state

### Configuration Testing
- **Reload config**: Restart nvim or use `:source %` in config files
- **Check health**: `:checkhealth` - Diagnoses configuration issues
- **Plugin health**: `:checkhealth lazy` - Checks plugin manager status

## Key Architecture Details

### Plugin Manager (lazy.nvim)
- Uses lazy loading for performance optimization
- Plugins are defined in separate files under `lua/plugins/`
- Each plugin file returns a configuration table
- Dependencies are automatically managed

### Configuration Structure
- **Modular design**: Each concern separated into its own file
- **Lazy loading**: Plugins load only when needed
- **Leader key**: Space (`<leader>`) for custom mappings
- **Performance optimized**: Disabled unused default plugins

### Key Components
- **Alpha**: Dashboard with custom ASCII art and quick actions
- **Telescope**: Fuzzy finder for files, recent files, and text search
- **Nvim-tree**: File explorer with tree view
- **Claude Code**: Integration plugin for AI-assisted development
- **Treesitter**: Syntax highlighting and code understanding
- **Colorschemes**: Multiple themes (tokyonight, kanagawa, cyberdream)

### Key Bindings Philosophy
- **Leader key** (`<space>`): Primary namespace for custom commands
- **jk**: Alternative escape from insert mode
- **Split management**: `<leader>s[hvex]` for window operations
- **Buffer navigation**: `<leader>[npx]` for buffer management
- **File operations**: `<leader>f[frs]` for file finding and searching
- **Tree operations**: `<leader>e[efcr]` for file explorer

### Settings Notable Points
- **Indentation**: 4 spaces (configured for personal preference)
- **Line numbers**: Relative numbering enabled
- **Search**: Case-smart search behavior
- **Clipboard**: System clipboard integration
- **Sessions**: Auto-session support for project state persistence

## Plugin Development Notes

When adding new plugins:
1. Create new file in `lua/plugins/` directory
2. Return a plugin specification table
3. Include dependencies if needed
4. Add keymaps within the plugin config function
5. Test with `:Lazy reload` to verify configuration

When modifying existing plugins:
1. Check current plugin configuration in respective file
2. Maintain the existing keymap conventions
3. Ensure changes are compatible with lazy loading
4. Update this documentation if architecture changes