# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Neovim Configuration Overview

This is a personal Neovim configuration built on the NvChad framework (v2.5), optimized for AI-assisted development and modern workflows. The configuration extends NvChad's robust foundation while maintaining framework compatibility and adding essential productivity tools.

## Development Commands

### Plugin Management
```bash
# Check plugin status
:Lazy

# Update all plugins (including NvChad)
:Lazy update

# Sync plugins with lockfile
:Lazy sync

# Install missing plugins
:Lazy install

# View plugin load times
:Lazy profile
```

### Configuration Testing
```bash
# Health check - diagnose issues
:checkhealth

# Check specific components
:checkhealth nvchad
:checkhealth lazy
:checkhealth lsp
:checkhealth mason

# Reload current config file
:source %

# Open Neovim config directory
:NvChad

# View startup time
:StartupTime
```

### LSP and Diagnostics
```bash
# LSP info for current buffer
:LspInfo

# Install/update language servers
:Mason

# Format current buffer
:lua require("conform").format()

# Show diagnostics
:lua vim.diagnostic.open_float()

# Go to next/previous diagnostic
]d / [d
```

### Search and Navigation
```bash
# Telescope commands (leader + f prefix)
<leader>ff  # Find files
<leader>fw  # Live grep
<leader>fb  # Find buffers
<leader>fh  # Help tags
<leader>fo  # Old files
<leader>fz  # Current buffer fuzzy find

# File explorer
<leader>e   # Toggle NvimTree
```

## Architecture and Key Components

### Core Structure
```
~/.config/nvim/
├── lua/
│   ├── chadrc.lua         # NvChad UI/theme configuration
│   ├── mappings.lua       # Key mappings with AI integration
│   ├── options.lua        # Core Neovim settings
│   ├── configs/           # Plugin configurations
│   │   ├── lspconfig.lua  # Language servers setup
│   │   ├── blink.lua      # Completion engine config
│   │   └── conform.lua    # Code formatting
│   ├── plugins/           # Custom plugin definitions
│   └── utils/             # Helper modules
│       ├── clipboard.lua  # Advanced clipboard for AI workflows
│       └── terminal-manager.lua # Claude/Gemini terminal management
```

### Key Integration Points

1. **AI Development Integration**
   - Claude Code terminal with smart toggle (`<leader>cc`)
   - Gemini CLI integration (`<leader>og`)
   - Advanced clipboard utilities for AI context sharing
   - Terminal manager for seamless AI tool switching

2. **Clipboard System** (utils/clipboard.lua)
   - File reference mode: `<leader>cpr` creates path:line references
   - Content compression: `<leader>cpp` for token-efficient copying
   - Smart segmentation for large selections
   - OSC 52 support for VM/SSH environments

3. **Terminal Management** (utils/terminal-manager.lua)
   - Intelligent detection of active AI terminals
   - Conflict-free switching between Claude Code and Gemini
   - State recovery and error handling
   - Floating window management

4. **Session Management**
   - Persistence.nvim for git-branch-aware sessions
   - Auto-cleanup of invalid buffers
   - Quick save/load workflow (`<leader>ps`, `<leader>pl`)

## Critical Implementation Details

### Plugin Loading Strategy
- NvChad provides base functionality - don't duplicate
- Custom plugins use `lazy = false` for immediate loading
- AI tools have high priority to ensure availability
- Dependencies are explicitly declared

### LSP Configuration
- Mason handles automatic LSP installation
- Server list in `lspconfig.lua`: html, cssls, jsonls, eslint, vtsls, phpactor, perlnavigator, vuels
- Auto-installation enabled via mason-lspconfig
- NvChad's LSP defaults are preserved

### Completion System (Blink.cmp)
- Replaces nvim-cmp with modern Rust-based engine
- Custom keymap avoids system shortcuts:
  - `<C-j>/<C-k>` for navigation (not arrow keys)
  - `<C-n>` to trigger completion (not Ctrl-Space)
  - `<Tab>` accepts suggestions
- Copilot integration via blink-copilot plugin

### Key Mappings Philosophy
- Leader key: `<space>`
- AI tools: `<leader>c*` namespace
- File operations: `<leader>f*` (Telescope)
- Session management: `<leader>p*`
- Copilot management: `<leader>co*`

## Development Workflows

### Adding New Plugins
1. Add to `lua/plugins/init.lua` with version tag
2. Follow NvChad's lazy.nvim patterns
3. Test theme compatibility with base46
4. Update lockfile after testing

### Modifying Configurations
1. Check NvChad defaults first (avoid duplication)
2. Use appropriate config file:
   - UI/themes: `chadrc.lua`
   - Keybindings: `mappings.lua`
   - Plugin configs: `lua/configs/`
3. Maintain framework compatibility

### Debugging Issues
1. Start with `:checkhealth`
2. Check `:messages` for errors
3. Use `:Lazy profile` for performance issues
4. Terminal issues: `<leader>ts` for status, `<leader>tr` to reset

## Common Tasks

### Format Code
```lua
-- Format current buffer
:lua require("conform").format()

-- To add formatter configuration, edit lua/configs/conform.lua
```

### Manage Copilot
```bash
<leader>cos  # Check status
<leader>coe  # Enable
<leader>cod  # Disable
<leader>cor  # Restart
```

### Work with AI Tools
```bash
# Toggle Claude Code
<leader>cc

# Toggle Gemini
<leader>og

# Switch between AI terminals
<leader>tt

# Copy code with file reference (saves tokens)
<leader>cpr  # In visual mode

# Send selection to Claude
<leader>cs   # In visual mode
```

## Performance Considerations

- Lazy loading handled by NvChad and lazy.nvim
- Blink.cmp uses Rust for faster completion
- Terminal managers avoid blocking operations
- Session persistence excludes invalid buffers
- Clipboard operations are async where possible