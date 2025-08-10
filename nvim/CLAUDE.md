# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Neovim Configuration Overview

This is a personal Neovim configuration built on the NvChad framework (v2.5), optimized for AI-assisted development and modern workflows. The configuration extends NvChad's robust foundation while maintaining framework compatibility and adding essential productivity tools.

## Security Architecture (Updated 2025)

### Layered Security System
This project implements a three-tier security strategy to balance security with usability:

#### Security Levels
- **basic**: Basic PATH validation, maximum compatibility, suitable for development
- **standard**: Standard security checks, balances security with usability (default)  
- **paranoid**: Enterprise-grade strict checks with CVE fixes and deep path validation

#### Configuration Methods
```lua
-- Method 1: Neovim global variable (recommended)
vim.g.terminal_security_level = "standard"

-- Method 2: Environment variable
export NVIM_SECURITY_LEVEL=standard

-- Method 3: Runtime switching
:lua require('utils.terminal.security').set_security_level('basic')
```

#### Health Check & Diagnostics
```lua
-- Check security configuration status
:lua print(vim.inspect(require('utils.terminal.security').health_check()))

-- Diagnose specific command issues
:lua require('utils.terminal.security-core').diagnose_command('claude')

-- Security audit
:lua require('utils.terminal.security').security_audit()
```

#### Module Structure
- **security.lua**: Unified interface with dynamic loading
- **security-core.lua**: Lightweight security (93 lines)
- **security-paranoid.lua**: Enterprise security (430+ lines)

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

### Core Structure (Updated - Optimized)
```
~/.config/nvim/
├── lua/
│   ├── chadrc.lua         # NvChad UI/theme configuration
│   ├── mappings.lua       # Key mappings with AI integration
│   ├── options.lua        # Core Neovim settings
│   ├── configs/           # Plugin configurations
│   │   ├── lspconfig.lua  # Enhanced LSP servers with diagnostics
│   │   ├── blink.lua      # Optimized completion engine (fixed sorting)
│   │   ├── conform.lua    # Extended code formatting support
│   │   └── telescope.lua  # File finder with improved navigation
│   ├── plugins/           # Custom plugin definitions
│   └── utils/             # Modular helper modules
│       ├── clipboard.lua  # Performance-optimized AI clipboard
│       ├── terminal/manager.lua    # Simplified coordinator (80% less code)
│       ├── terminal/adapters/claude.lua     # Claude Code management
│       ├── terminal/adapters/gemini.lua     # Gemini CLI management
│       ├── terminal/state.lua      # Centralized state management
│       └── error-handler.lua       # Lightweight error wrapper
```

### Key Integration Points (Updated - Optimized)

1. **AI Development Integration**
   - Claude Code terminal with smart toggle (`<leader>cc`)
   - Gemini CLI integration (`<leader>gm`)
   - Advanced clipboard utilities for AI context sharing
   - Modular terminal management for better maintainability

2. **Optimized Clipboard System** (utils/clipboard.lua)
   - File reference mode: `<leader>cpr` creates path:line references (saves ~70% tokens)
   - Performance-optimized content processing (50% faster)
   - Enhanced security checks with minimal overhead
   - Smart segmentation for large selections
   - OSC 52 support for VM/SSH environments

3. **Lightweight Adapter Terminal Management (Plan A Complete)**
   - **terminal/manager.lua**: Enhanced coordinator with error recovery
   - **terminal/adapters/claude.lua**: Lightweight Claude adapter (207 lines, -50% from original)
   - **terminal/adapters/gemini.lua**: Lightweight Gemini adapter (258 lines, -34% from original)
   - **terminal/state.lua**: Centralized state management
   - **Unified Architecture**: Pure modular design with lightweight adapters
   - **Backward Compatibility**: Complete API compatibility via transition aliases

4. **Enhanced Completion System** (configs/blink.lua)
   - **Fixed sorting issue**: `:e ~/.cla` now prioritizes `.cla*` files correctly
   - Precise fuzzy matching for better accuracy
   - Command-line specific optimizations
   - Reduced interference from frequency-based suggestions

5. **Session Management**
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