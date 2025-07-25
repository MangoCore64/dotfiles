#!/bin/bash

# Dotfiles 安裝腳本
# 用於在新機器上快速同步設定檔案

set -e

# 檢查和設定腳本權限
check_script_permissions() {
    local script_path="${BASH_SOURCE[0]}"
    local script_perms
    
    # 獲取腳本權限
    if [[ "$OSTYPE" == "darwin"* ]]; then
        script_perms=$(stat -f "%A" "$script_path" 2>/dev/null || echo "000")
    else
        script_perms=$(stat -c "%a" "$script_path" 2>/dev/null || echo "000")
    fi
    
    # 檢查權限是否為 755 或 750
    if [[ "$script_perms" != "755" && "$script_perms" != "750" ]]; then
        log_warning "腳本權限不安全 (當前: $script_perms)，正在修正為 755"
        if ! chmod 755 "$script_path"; then
            log_error "無法修正腳本權限"
            return 1
        fi
        log_success "腳本權限已修正為 755"
    fi
    
    return 0
}

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 輔助函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 備份現有檔案
backup_file() {
    local file=$1
    
    # 檢查輸入參數
    if [ -z "$file" ]; then
        log_error "backup_file: 缺少檔案路徑參數"
        return 1
    fi
    
    # 檢查檔案或目錄是否存在
    if [ -f "$file" ] || [ -d "$file" ]; then
        local backup_name="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warning "備份現有檔案: $file -> $backup_name"
        
        # 嘗試移動檔案，並檢查是否成功
        if ! mv "$file" "$backup_name"; then
            log_error "備份失敗: 無法移動 $file 到 $backup_name"
            return 1
        fi
        
        # 驗證備份是否成功建立
        if [ ! -e "$backup_name" ]; then
            log_error "備份驗證失敗: $backup_name 不存在"
            return 1
        fi
        
        log_success "備份成功: $backup_name"
    fi
    
    return 0
}

# 檢測系統和包管理器
detect_system() {
    log_info "檢測系統環境..."
    
    case "$(uname -s)" in
        Darwin)
            SYSTEM="macos"
            if command -v brew &> /dev/null; then
                PKG_MANAGER="brew"
                INSTALL_CMD="brew install"
            else
                PKG_MANAGER="none"
                log_warning "macOS 系統但未安裝 Homebrew"
            fi
            ;;
        Linux)
            SYSTEM="linux"
            if command -v apt-get &> /dev/null; then
                PKG_MANAGER="apt"
                INSTALL_CMD="sudo apt-get update && sudo apt-get install -y"
                # 檢查是否有 sudo 權限
                if ! sudo -n true 2>/dev/null; then
                    log_warning "需要 sudo 權限來安裝套件"
                fi
            elif command -v yum &> /dev/null; then
                PKG_MANAGER="yum"
                INSTALL_CMD="sudo yum install -y"
            elif command -v dnf &> /dev/null; then
                PKG_MANAGER="dnf"
                INSTALL_CMD="sudo dnf install -y"
            elif command -v pacman &> /dev/null; then
                PKG_MANAGER="pacman"
                INSTALL_CMD="sudo pacman -S --noconfirm"
            else
                PKG_MANAGER="none"
                log_warning "未找到支援的 Linux 包管理器"
            fi
            ;;
        *)
            SYSTEM="unknown"
            PKG_MANAGER="none"
            log_warning "未知的作業系統: $(uname -s)"
            ;;
    esac
    
    log_info "系統: $SYSTEM, 包管理器: $PKG_MANAGER"
}

# 安裝缺失的依賴程式
install_dependencies() {
    local missing_deps=("$@")
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        return 0
    fi
    
    if [ "$PKG_MANAGER" = "none" ]; then
        log_error "無法自動安裝缺失的程式，請手動安裝："
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        return 1
    fi
    
    echo
    log_info "將安裝以下缺失的程式："
    for dep in "${missing_deps[@]}"; do
        echo "  - $dep"
    done
    echo
    log_info "安裝命令: $INSTALL_CMD ${missing_deps[*]}"
    echo
    
    # 使用者確認
    read -p "是否繼續安裝？[y/N]: " -n 1 -r confirm
    echo
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_warning "使用者取消安裝，部分功能可能無法使用"
        return 1
    fi
    
    # 執行安裝
    log_info "正在安裝缺失的程式..."
    if eval "$INSTALL_CMD ${missing_deps[*]}"; then
        log_success "程式安裝完成"
        return 0
    else
        log_error "程式安裝失敗"
        return 1
    fi
}

# 檢查必要工具
check_dependencies() {
    log_info "檢查必要工具..."
    
    local tools=("vim" "tmux")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_warning "缺少必要工具: ${missing_tools[*]}"
        
        # 如果啟用自動安裝選項
        if [ "$AUTO_INSTALL_DEPS" = "true" ]; then
            if install_dependencies "${missing_tools[@]}"; then
                log_success "所有必要工具已安裝"
            else
                log_error "無法自動安裝缺失工具，請手動安裝後重試"
                exit 1
            fi
        else
            log_error "請先安裝這些工具再執行安裝腳本"
            log_info "或使用 --install-deps 選項自動安裝"
            exit 1
        fi
    else
        log_success "所有必要工具已安裝"
    fi
}

# 安裝 vim 設定
install_vim() {
    log_info "安裝 vim 設定..."
    
    # 備份現有 .vimrc
    if ! backup_file "$HOME/.vimrc"; then
        log_error "無法備份現有的 .vimrc，安裝中止"
        return 1
    fi
    
    # 複製新的 .vimrc
    cp .vimrc "$HOME/.vimrc"
    
    # 設定安全權限 (使用者讀寫，群組和其他使用者唯讀)
    chmod 644 "$HOME/.vimrc"
    
    # 安裝 vim-plug（如果尚未安裝）
    if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
        log_info "安裝 vim-plug..."
        local plug_url="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
        local expected_hash="c2d8998469a049a51225a71128a12917b379822d16b639493e29ea02d8787306"
        local temp_file="/tmp/plug.vim.$$"
        
        # 下載到臨時檔案，設定超時和重試限制
        if ! curl -fLo "$temp_file" --connect-timeout 30 --max-time 120 --retry 3 "$plug_url"; then
            log_error "vim-plug 下載失敗"
            rm -f "$temp_file"
            return 1
        fi
        
        # 驗證完整性
        local actual_hash
        if command -v shasum &> /dev/null; then
            actual_hash=$(shasum -a 256 "$temp_file" | cut -d' ' -f1)
        elif command -v sha256sum &> /dev/null; then
            actual_hash=$(sha256sum "$temp_file" | cut -d' ' -f1)
        else
            log_warning "無法驗證 vim-plug 完整性：缺少 shasum 或 sha256sum"
            # 繼續安裝但發出警告
            mkdir -p "$HOME/.vim/autoload"
            mv "$temp_file" "$HOME/.vim/autoload/plug.vim"
            log_success "vim-plug 安裝完成（未驗證完整性）"
            return 0
        fi
        
        if [ "$actual_hash" = "$expected_hash" ]; then
            mkdir -p "$HOME/.vim/autoload"
            mv "$temp_file" "$HOME/.vim/autoload/plug.vim"
            log_success "vim-plug 安裝完成（完整性已驗證）"
        else
            log_error "vim-plug 完整性驗證失敗"
            log_error "預期: $expected_hash"
            log_error "實際: $actual_hash"
            
            # 檢查是否跳過雜湊驗證（用於測試或緊急情況）
            if [ "$SKIP_HASH_CHECK" = "true" ]; then
                log_warning "跳過雜湊驗證（SKIP_HASH_CHECK=true）"
                mkdir -p "$HOME/.vim/autoload"
                mv "$temp_file" "$HOME/.vim/autoload/plug.vim"
                log_success "vim-plug 安裝完成（未驗證完整性）"
            else
                log_error "設定 SKIP_HASH_CHECK=true 可跳過驗證"
                rm -f "$temp_file"
                return 1
            fi
        fi
    fi
    
    log_success "vim 設定安裝完成"
    log_info "請開啟 vim 並執行 :PlugInstall 來安裝 plugins"
}

# 安裝 tmux 設定
install_tmux() {
    log_info "安裝 tmux 設定..."
    
    # 備份現有 .tmux.conf
    if ! backup_file "$HOME/.tmux.conf"; then
        log_error "無法備份現有的 .tmux.conf，安裝中止"
        return 1
    fi
    
    # 複製新的 .tmux.conf
    cp .tmux.conf "$HOME/.tmux.conf"
    
    # 設定安全權限
    chmod 644 "$HOME/.tmux.conf"
    
    log_success "tmux 設定安裝完成"
    log_info "請重啟 tmux 或執行 'tmux source-file ~/.tmux.conf' 來套用新設定"
}

# 安裝 nvim 設定 (完整 NvChad 配置含自定義功能)
install_nvim() {
    if ! command -v nvim &> /dev/null; then
        log_warning "未找到 nvim，跳過 nvim 設定安裝"
        return
    fi
    
    log_info "安裝 nvim 設定 (完整 NvChad 配置)..."
    
    # 檢查 nvim 配置來源是否存在
    if [ ! -d "nvim" ]; then
        log_error "找不到 nvim 配置目錄，請確認在 dotfiles 目錄中執行"
        return 1
    fi
    
    # 備份現有配置
    if [ -d "$HOME/.config/nvim" ]; then
        log_info "發現現有的 nvim 配置，將進行備份"
        if ! backup_file "$HOME/.config/nvim"; then
            log_error "無法備份現有的 nvim 配置，安裝中止"
            return 1
        fi
    fi
    
    # 建立 .config 目錄（如果不存在）
    mkdir -p "$HOME/.config"
    
    # 直接複製完整的自定義 NvChad 配置
    log_info "複製完整 NvChad 配置（包含智能剪貼簿、Claude Code 等功能）..."
    cp -r nvim "$HOME/.config/"
    
    # 設定目錄和檔案權限
    find "$HOME/.config/nvim" -type d -exec chmod 755 {} \;
    find "$HOME/.config/nvim" -type f -exec chmod 644 {} \;
    
    log_success "完整 NvChad 配置安裝完成"
    log_info "配置包含以下功能："
    echo "  - 智能剪貼簿系統 (<leader>cpr, <leader>cp)"
    echo "  - Claude Code AI 助手 (<leader>cc)"
    echo "  - 自動會話管理"
    echo "  - NvChad 完整功能"
    log_info "請開啟 nvim，將自動安裝所需 plugins"
    log_info "詳細說明請參考: ~/dotfiles/nvim/CLAUDE.md"
}

# 驗證配置檔案語法
validate_config() {
    local config_type=$1
    local config_file=$2
    
    case $config_type in
        "vim")
            if command -v vim &> /dev/null; then
                # 在 VM 環境中跳過 vim 語法驗證，避免卡住
                if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ "$TERM" = "dumb" ]; then
                    log_info "檢測到 VM/SSH 環境，跳過 vim 配置語法驗證"
                    return 0
                fi
                
                # 在本地環境中進行基本語法檢查，設定超時
                local temp_dir=$(mktemp -d)
                if ! timeout 10 bash -c "(cd '$temp_dir' && vim -T dumb -n -i NONE -e -s -S '$config_file' +qall)" 2>/dev/null; then
                    log_warning "vim 配置檔案語法可能有問題: $config_file"
                    rm -rf "$temp_dir"
                    return 1
                fi
                rm -rf "$temp_dir"
            fi
            ;;
        "tmux")
            if command -v tmux &> /dev/null; then
                # 在 VM 環境中跳過 tmux 複雜驗證，避免卡住
                if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ "$TERM" = "dumb" ]; then
                    log_info "檢測到 VM/SSH 環境，跳過 tmux 配置驗證"
                    return 0
                fi
                
                if ! timeout 5 tmux -f "$config_file" list-sessions &>/dev/null; then
                    # tmux 配置驗證較複雜，只做基本檢查
                    if ! grep -E "^[[:space:]]*#|^[[:space:]]*$|^[[:space:]]*[a-zA-Z]" "$config_file" >/dev/null; then
                        log_warning "tmux 配置檔案格式可能有問題: $config_file"
                        return 1
                    fi
                fi
            fi
            ;;
        "nvim")
            if command -v nvim &> /dev/null; then
                # 在 VM 環境中跳過 nvim 語法驗證，避免卡住
                if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ "$TERM" = "dumb" ]; then
                    log_info "檢測到 VM/SSH 環境，跳過 nvim 配置語法驗證"
                    return 0
                fi
                
                # 檢查 lua 配置基本語法
                if [ -f "$config_file/init.lua" ]; then
                    if command -v lua &> /dev/null; then
                        if ! timeout 5 lua -e "dofile('$config_file/init.lua')" 2>/dev/null; then
                            log_warning "nvim 配置可能有語法問題"
                            return 1
                        fi
                    fi
                fi
            fi
            ;;
    esac
    
    return 0
}

# 驗證安裝
verify_installation() {
    log_info "驗證安裝..."
    
    local errors=0
    local warnings=0
    
    # 檢查 vim 設定
    if [ -f "$HOME/.vimrc" ]; then
        log_success "vim 設定檔案存在"
        if ! validate_config "vim" "$HOME/.vimrc"; then
            ((warnings++))
        fi
    else
        log_error "vim 設定檔案不存在"
        ((errors++))
    fi
    
    # 檢查 tmux 設定
    if [ -f "$HOME/.tmux.conf" ]; then
        log_success "tmux 設定檔案存在"
        if ! validate_config "tmux" "$HOME/.tmux.conf"; then
            ((warnings++))
        fi
    else
        log_error "tmux 設定檔案不存在"
        ((errors++))
    fi
    
    # 檢查 nvim 設定（如果 nvim 存在）
    if command -v nvim &> /dev/null; then
        if [ -d "$HOME/.config/nvim" ]; then
            log_success "nvim 設定目錄存在"
            if ! validate_config "nvim" "$HOME/.config/nvim"; then
                ((warnings++))
            fi
        else
            log_error "nvim 設定目錄不存在"
            ((errors++))
        fi
    fi
    
    # 檢查檔案權限
    log_info "檢查檔案權限..."
    local perm_errors=0
    
    if [ -f "$HOME/.vimrc" ]; then
        local vimrc_perms
        if [[ "$OSTYPE" == "darwin"* ]]; then
            vimrc_perms=$(stat -f "%A" "$HOME/.vimrc" 2>/dev/null || echo "000")
        else
            vimrc_perms=$(stat -c "%a" "$HOME/.vimrc" 2>/dev/null || echo "000")
        fi
        
        if [ "$vimrc_perms" != "644" ]; then
            log_warning ".vimrc 權限不標準 (當前: $vimrc_perms, 建議: 644)"
            ((warnings++))
        fi
    fi
    
    # 報告結果
    if [ $errors -eq 0 ]; then
        if [ $warnings -eq 0 ]; then
            log_success "所有設定檔案安裝並驗證成功！"
        else
            log_success "設定檔案安裝完成，發現 $warnings 個警告"
        fi
    else
        log_error "發現 $errors 個錯誤和 $warnings 個警告"
        exit 1
    fi
}

# 顯示使用說明
show_usage() {
    echo "用法: $0 [選項]"
    echo "選項:"
    echo "  -h, --help          顯示此說明"
    echo "  -v, --vim           僅安裝 vim 設定"
    echo "  -t, --tmux          僅安裝 tmux 設定"
    echo "  -n, --nvim          僅安裝 nvim 設定"
    echo "  -a, --all           安裝所有設定 (預設)"
    echo "  --install-deps      自動安裝缺失的相依程式"
    echo "  --check-only        僅檢查相依程式狀況，不安裝設定"
    echo ""
    echo "範例:"
    echo "  $0                  # 安裝所有設定"
    echo "  $0 --vim            # 僅安裝 vim 設定"
    echo "  $0 --install-deps   # 自動安裝缺失程式並安裝設定"
    echo "  $0 --check-only     # 僅檢查相依程式狀況"
}

# 主程式
main() {
    log_info "開始安裝 dotfiles..."
    
    # 檢查腳本權限
    check_script_permissions
    
    # 切換到腳本所在目錄
    cd "$(dirname "${BASH_SOURCE[0]}")"
    
    # 解析命令列參數
    local install_vim=false
    local install_tmux_flag=false
    local install_nvim_flag=false
    local install_all=true
    local check_only=false
    AUTO_INSTALL_DEPS=false  # 全域變數
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--vim)
                install_vim=true
                install_all=false
                shift
                ;;
            -t|--tmux)
                install_tmux_flag=true
                install_all=false
                shift
                ;;
            -n|--nvim)
                install_nvim_flag=true
                install_all=false
                shift
                ;;
            -a|--all)
                install_all=true
                shift
                ;;
            --install-deps)
                AUTO_INSTALL_DEPS=true
                shift
                ;;
            --check-only)
                check_only=true
                shift
                ;;
            *)
                log_error "未知選項: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # 檢測系統環境
    detect_system
    
    # 檢查必要工具
    check_dependencies
    
    # 如果只是檢查模式，在此結束
    if [ "$check_only" = "true" ]; then
        log_success "相依程式檢查完成"
        if command -v nvim &> /dev/null; then
            log_info "nvim 已安裝，可使用完整功能"
        else
            log_info "nvim 未安裝，可選擇安裝以獲得額外功能"
        fi
        exit 0
    fi
    
    # 執行安裝
    if $install_all; then
        install_vim
        install_tmux
        install_nvim
    else
        if $install_vim; then
            install_vim
        fi
        if $install_tmux_flag; then
            install_tmux
        fi
        if $install_nvim_flag; then
            install_nvim
        fi
    fi
    
    # 驗證安裝
    verify_installation
    
    log_success "Dotfiles 安裝完成！"
    echo ""
    log_info "後續步驟："
    echo "1. 重啟終端或執行 source ~/.bashrc"
    echo "2. 開啟 vim 並執行 :PlugInstall 安裝 plugins"
    echo "3. 重啟 tmux 或執行 tmux source-file ~/.tmux.conf"
    if command -v nvim &> /dev/null; then
        echo "4. 開啟 nvim，NvChad 會自動安裝所有 plugins"
        echo "5. 測試智能剪貼簿：選取代碼後按 <leader>cpr"
        echo "6. 測試 Claude Code：按 <leader>cc 開啟 AI 助手"
        echo "7. 參考 ~/dotfiles/nvim/CLAUDE.md 了解完整功能"
    fi
}

# 執行主程式
main "$@"