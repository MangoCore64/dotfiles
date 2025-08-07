# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing configuration files for vim, tmux, and neovim. The repository includes an automated installation script and comprehensive configurations optimized for development productivity.

## File Structure

```
.
├── .vimrc              # Vim configuration with vim-plug and AI plugins
├── .tmux.conf          # Tmux configuration with Ctrl-a prefix
├── .claude/            # Claude Code configuration directory
│   └── agents/         # Specialized sub-agents for different domains
├── bin/                # Utility scripts and binaries
├── nvim/               # Neovim configuration (NvChad v2.5-based)
│   ├── init.lua        # NvChad bootstrap entry point
│   ├── lazy-lock.json  # Plugin version lockfile
│   ├── docs/           # Complete documentation system
│   │   ├── QUICKSTART.md      # Quick setup guide
│   │   ├── USER_GUIDE.md      # Comprehensive user manual
│   │   ├── ARCHITECTURE.md    # System architecture overview
│   │   ├── API_REFERENCE.md   # API documentation
│   │   ├── EXTENDING.md       # Extension guide
│   │   ├── TERMINAL_ARCHITECTURE.md  # Terminal system details
│   │   └── TROUBLESHOOTING.md # Troubleshooting guide
│   ├── lua/            # Configuration modules
│   │   ├── configs/    # Plugin configurations
│   │   ├── plugins/    # Plugin management
│   │   └── utils/      # Utility modules
│   │       ├── clipboard/  # Modular clipboard system
│   │       └── terminal/   # Modular terminal management
│   ├── scripts/        # Development and maintenance scripts
│   │   └── run_tests.sh    # Test execution script
│   └── tests/          # Comprehensive test suite
│       ├── clipboard/      # Clipboard functionality tests
│       ├── terminal/       # Terminal management tests
│       ├── test_runner.lua # Test orchestration
│       └── test_utils.lua  # Testing utilities
├── install.sh          # Automated installation script with security features
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
- **Run Test Suite**: Execute `./nvim/scripts/run_tests.sh` or `nvim -c "luafile tests/test_runner.lua"`
- **Validate Architecture**: Use `nvim/docs/ARCHITECTURE.md` for system design verification
- **Run Tests**: `cd nvim && ./scripts/run_tests.sh` for comprehensive testing
- **Health Check**: `nvim +checkhealth +qa` to verify configuration

### Maintenance Commands
- **Vim plugin updates**: `:PlugUpdate` in vim
- **Neovim plugin management**: `:Lazy` interface for plugin operations
- **Clear neovim cache**: `rm -rf ~/.local/share/nvim ~/.cache/nvim`
- **Test system health**: `./nvim/scripts/run_tests.sh --health-check`
- **Monitor performance**: Built-in performance monitor in `utils/performance-monitor.lua`
- **Debug terminal issues**: Use test files in `tests/terminal/` for diagnosis
- **Full test suite**: `cd nvim && ./scripts/run_tests.sh`
- **Security audit**: Check `nvim/tests/terminal/penetration_test.lua`
- **Performance monitoring**: Built-in performance-monitor.lua

## Architecture Details

### Installation Script (`install.sh`)
- **Security-focused**: 
  - URL validation for all downloads
  - SHA256 checksums for file integrity
  - Script permission verification
  - Safe path execution only
- **Backup system**: 
  - Automatic timestamp-based backups
  - Cleanup of temporary backup directories
  - Restore functionality for failed installations
- **Cross-platform**: 
  - macOS and Linux environments
  - **macOS Homebrew optimization**: Auto-detection of `/opt/homebrew/bin/`
  - Package manager detection (brew, apt, yum, dnf, pacman)
- **Error handling**: 
  - Comprehensive logging and error recovery
  - Retry logic for network operations
  - Graceful degradation when tools unavailable

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
- **Framework**: Based on NvChad v2.5 with proven defaults and modern optimizations
- **Plugin manager**: lazy.nvim with version-locked critical components
- **Leader key**: Space for custom mappings
- **AI integration**: 
  - Claude Code plugin with intelligent terminal management
  - GitHub Copilot integration with blink.cmp
  - Dual-terminal system (Claude + Gemini) with smart switching
- **Session management**: Auto-session for project state persistence
- **Modular architecture**: Separate clipboard/ and terminal/ modules for maintainability
- **Comprehensive testing**: 32+ test files covering all major functionality
- **macOS optimizations**: Homebrew path support, platform-specific terminal handling
- **Security**: Enhanced OSC 52 controls and path validation
- **macOS Optimization**: Homebrew path support and startup retry logic

## Development Guidelines

### When modifying configurations:
1. **Test-driven approach**: Always run tests first using `cd nvim && ./scripts/run_tests.sh`
2. **Documentation updates**: Update both CLAUDE.md and relevant `docs/` files
3. **Cross-platform compatibility**: Test on both macOS and Linux environments
4. **Security considerations**: Follow security patterns in `utils/*/security.lua`
5. **Version management**: Use locked versions for critical AI tools, flexible for mature plugins
6. **Modular design**: Keep clipboard and terminal systems as separate, testable modules
7. **Backup strategy**: Update install script backup functionality if needed

### When working with Neovim:
1. **Respect NvChad's architecture** and conventions
2. Add custom plugins to `lua/plugins/init.lua`
3. Use `chadrc.lua` for theme and UI customizations
4. **Test compatibility** with NvChad's plugin ecosystem
5. **Use modular architecture**: Place utilities in `lua/utils/`
6. **Follow security guidelines**: Validate paths and inputs
7. **Performance considerations**: Use error-handler.lua and performance-monitor.lua

### Security & Quality Assurance:
- Install script should maintain 755 permissions
- Configuration files should be readable but not executable
- **Never commit sensitive information** or API keys
- **Run security tests**: `nvim/tests/terminal/penetration_test.lua`
- **URL validation**: All downloads must pass validation
- **Path restrictions**: Only allow safe execution paths
- **Backup strategy**: Timestamp-based backups with cleanup

## Testing & Quality Assurance Workflow

### Pre-commit Testing
```bash
# Run comprehensive test suite
cd nvim && ./scripts/run_tests.sh

# Verify configuration health
nvim +checkhealth +qa

# Security audit
nvim --headless -c "luafile nvim/tests/terminal/penetration_test.lua" -c "qa"
```

### Continuous Integration
- **Automated tests**: All commits trigger test suite
- **Security scanning**: URL validation and path security
- **Performance benchmarks**: Monitor terminal startup times
- **Cross-platform verification**: macOS and Linux compatibility

## Commit Message Guidelines

- Use descriptive commit messages in Chinese (traditional/simplified)
- Focus on the specific change rather than generic descriptions
- Standard format: `修正/新增/更新 [component] [description]`
- **Include test status**: Mention if tests pass/fail
- **Security notes**: Flag security-related changes

## Claude Code Sub-Agents

This repository includes specialized sub-agents configured for different development domains. These agents are automatically available when using Claude Code and provide expert-level assistance:

### Development Technology Stack
- **frontend-developer**: React/Vue/Angular, CSS frameworks, responsive design, state management
- **backend-specialist**: Node.js/Python/Go/Java, API design, microservices, cloud infrastructure  
- **php-expert**: Laravel/Symfony, modern PHP 8.0+, legacy modernization, security practices
- **perl-expert**: Modern Perl development, bioinformatics, system administration, text processing

### Infrastructure & Security
- **database-specialist**: PostgreSQL/MySQL/MongoDB, performance optimization, migrations, high availability
- **devops-sre-specialist**: CI/CD, Docker/Kubernetes, Infrastructure as Code, monitoring, incident response
- **security-expert**: Application security, penetration testing, OWASP compliance, threat modeling

### AI & Specialized Tools  
- **prompt-engineer**: AI prompt optimization, LLM interactions, advanced prompting techniques
- **agent-orchestration-expert**: Multi-agent systems, workflow orchestration, distributed AI architectures
- **vim-neovim-expert**: Vim/Neovim configuration, plugin management, advanced editing techniques
- **search-tech-specialist**: Elasticsearch/Solr, search relevance, vector search, analytics

### System Built-in Agents
- **debugger**: Error diagnosis and troubleshooting
- **code-reviewer**: Code quality and security review  
- **test-runner**: Testing automation and analysis
- **dx-optimizer**: Developer experience improvements
- **meta-agent**: Creating new sub-agent configurations

### Usage
These agents are automatically invoked based on context, or you can explicitly request them:
- "Use the frontend-developer to optimize this React component"
- "Ask the security-expert to review this authentication code"
- "Have the database-specialist design this schema"

## Documentation Architecture

The project now includes comprehensive documentation in `nvim/docs/`:

### Core Documentation Files
- **QUICKSTART.md**: 5-minute setup guide
- **USER_GUIDE.md**: Complete feature walkthrough  
- **ARCHITECTURE.md**: System design and module structure
- **API_REFERENCE.md**: Complete API documentation
- **EXTENDING.md**: Custom development guidelines
- **TROUBLESHOOTING.md**: Common issues and solutions
- **TERMINAL_ARCHITECTURE.md**: Terminal system deep dive

### Testing & Quality Assurance
- **Test Suite**: Located in `nvim/tests/`
  - Terminal system tests: `nvim/tests/terminal/`
  - Clipboard functionality tests: `nvim/tests/clipboard/`
  - End-to-end workflow tests: `e2e_*.lua`
  - Security penetration tests: `penetration_test.lua`
- **Test Execution**: `cd nvim && ./scripts/run_tests.sh`
- **Performance Monitoring**: Built-in `performance-monitor.lua`
- **Error Handling**: Unified `error-handler.lua` system

## Recent Architectural Improvements (2025-08)

### macOS Terminal Optimization
- **Homebrew Path Support**: Automatic detection of `/opt/homebrew/bin/`
- **Startup Retry Logic**: Enhanced reliability for macOS environments
- **Platform-Specific Configuration**: Smart macOS detection and optimization

### Security Enhancements
- **Path Validation**: Comprehensive security checks in `terminal/security.lua`
- **OSC 52 Controls**: Secure clipboard handling with opt-in policies
- **Download Verification**: SHA256 checksums and URL validation
- **Backup Management**: Automatic cleanup of temporary backup directories

### Developer Experience
- **Comprehensive Documentation**: Complete docs/ directory structure
- **Test Coverage**: Extensive test suite covering all major components
- **Error Diagnostics**: Enhanced logging and error reporting
- **Performance Monitoring**: Built-in performance tracking

## Testing and Quality Assurance

### Comprehensive Test Suite
- **Location**: `nvim/tests/` directory with 32+ professional test files
- **Terminal System Tests**: 15+ tests covering Claude Code/Gemini AI integration
  - **State management**: Terminal buffer lifecycle and synchronization
  - **Security**: Path validation and command whitelisting
  - **Platform support**: macOS Homebrew paths and platform-specific optimizations
- **Clipboard System Tests**: 8+ tests for modular architecture and security
  - **API compatibility**: Backward compatibility and critical fixes verification
  - **Security hardening**: Input validation and sensitive content detection
  - **Modular refactoring**: Component isolation and interface testing

### Test Execution
```bash
# Run all tests
cd nvim && ./scripts/run_tests.sh

# Run specific test category
nvim -c "luafile tests/terminal/test_*.lua"
nvim -c "luafile tests/clipboard/test_*.lua"

# Health check mode
./scripts/run_tests.sh --health-check
```

### Development Documentation System
- **Architecture**: `nvim/docs/ARCHITECTURE.md` - Complete system design and module structure
- **API Reference**: `nvim/docs/API_REFERENCE.md` - Comprehensive API documentation
- **User Guide**: `nvim/docs/USER_GUIDE.md` - Detailed usage and feature guide
- **Troubleshooting**: `nvim/docs/TROUBLESHOOTING.md` - Debugging guide and solutions
- **Extension Guide**: `nvim/docs/EXTENDING.md` - Custom development guidelines
- **Quick Start**: `nvim/docs/QUICKSTART.md` - 5-minute setup and basics
- **Terminal Architecture**: `nvim/docs/TERMINAL_ARCHITECTURE.md` - Terminal system details

## NvChad Best Practices

當使用框架如 NvChad 時，最好：
1. **先使用框架的默認配置**
2. **只在必要時進行最小化的自定義**
3. **避免覆蓋複雜的嵌套配置結構** 
4. **測試每個修改的影響**
5. **使用模組化架構**：將自定義功能放在 `lua/utils/`
6. **遵循安全指導原則**：驗證所有外部輸入
7. **運行測試套件**：確保改動不破壞現有功能