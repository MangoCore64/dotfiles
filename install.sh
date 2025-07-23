#!/bin/bash

# Dotfiles 安裝腳本
# 用於在新機器上快速同步設定檔案

set -e

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
    if [ -f "$file" ] || [ -d "$file" ]; then
        local backup_name="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warning "備份現有檔案: $file -> $backup_name"
        mv "$file" "$backup_name"
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
        log_error "缺少必要工具: ${missing_tools[*]}"
        log_info "請先安裝這些工具再執行安裝腳本"
        exit 1
    fi
    
    log_success "所有必要工具已安裝"
}

# 安裝 vim 設定
install_vim() {
    log_info "安裝 vim 設定..."
    
    # 備份現有 .vimrc
    backup_file "$HOME/.vimrc"
    
    # 複製新的 .vimrc
    cp .vimrc "$HOME/.vimrc"
    
    # 安裝 vim-plug（如果尚未安裝）
    if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
        log_info "安裝 vim-plug..."
        curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        log_success "vim-plug 安裝完成"
    fi
    
    log_success "vim 設定安裝完成"
    log_info "請開啟 vim 並執行 :PlugInstall 來安裝 plugins"
}

# 安裝 tmux 設定
install_tmux() {
    log_info "安裝 tmux 設定..."
    
    # 備份現有 .tmux.conf
    backup_file "$HOME/.tmux.conf"
    
    # 複製新的 .tmux.conf
    cp .tmux.conf "$HOME/.tmux.conf"
    
    log_success "tmux 設定安裝完成"
    log_info "請重啟 tmux 或執行 'tmux source-file ~/.tmux.conf' 來套用新設定"
}

# 安裝 nvim 設定
install_nvim() {
    if ! command -v nvim &> /dev/null; then
        log_warning "未找到 nvim，跳過 nvim 設定安裝"
        return
    fi
    
    log_info "安裝 nvim 設定..."
    
    # 備份現有 nvim 設定目錄
    backup_file "$HOME/.config/nvim"
    
    # 建立 .config 目錄（如果不存在）
    mkdir -p "$HOME/.config"
    
    # 複製 nvim 設定目錄
    cp -r nvim "$HOME/.config/"
    
    log_success "nvim 設定安裝完成"
    log_info "請開啟 nvim，Lazy.nvim 會自動安裝所需 plugins"
}

# 驗證安裝
verify_installation() {
    log_info "驗證安裝..."
    
    local errors=0
    
    # 檢查 vim 設定
    if [ ! -f "$HOME/.vimrc" ]; then
        log_error "vim 設定檔案不存在"
        ((errors++))
    fi
    
    # 檢查 tmux 設定
    if [ ! -f "$HOME/.tmux.conf" ]; then
        log_error "tmux 設定檔案不存在"
        ((errors++))
    fi
    
    # 檢查 nvim 設定（如果 nvim 存在）
    if command -v nvim &> /dev/null && [ ! -d "$HOME/.config/nvim" ]; then
        log_error "nvim 設定目錄不存在"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "所有設定檔案安裝成功！"
    else
        log_error "發現 $errors 個錯誤"
        exit 1
    fi
}

# 顯示使用說明
show_usage() {
    echo "用法: $0 [選項]"
    echo "選項:"
    echo "  -h, --help      顯示此說明"
    echo "  -v, --vim       僅安裝 vim 設定"
    echo "  -t, --tmux      僅安裝 tmux 設定"
    echo "  -n, --nvim      僅安裝 nvim 設定"
    echo "  -a, --all       安裝所有設定 (預設)"
    echo ""
    echo "範例:"
    echo "  $0              # 安裝所有設定"
    echo "  $0 --vim        # 僅安裝 vim 設定"
    echo "  $0 --tmux       # 僅安裝 tmux 設定"
}

# 主程式
main() {
    log_info "開始安裝 dotfiles..."
    
    # 切換到腳本所在目錄
    cd "$(dirname "${BASH_SOURCE[0]}")"
    
    # 解析命令列參數
    local install_vim=false
    local install_tmux_flag=false
    local install_nvim_flag=false
    local install_all=true
    
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
            *)
                log_error "未知選項: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # 檢查必要工具
    check_dependencies
    
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
        echo "4. 開啟 nvim，Lazy.nvim 會自動安裝 plugins"
    fi
}

# 執行主程式
main "$@"