#!/bin/bash

# Dotfiles 安裝腳本
# 用於在新機器上快速同步設定檔案

# 移除 set -e，改用明確的錯誤處理
# set -e

# URL 安全驗證函數
validate_url() {
    local url="$1"
    local description="${2:-URL}"
    
    # 檢查必要參數
    if [ -z "$url" ]; then
        log_error "validate_url: 缺少 URL 參數"
        return 1
    fi
    
    # 檢查 URL 格式
    if [[ ! "$url" =~ ^https?://[a-zA-Z0-9.-]+[a-zA-Z0-9]/.*$ ]]; then
        log_error "$description 格式無效: $url"
        return 1
    fi
    
    # 檢查協議安全性
    if [[ ! "$url" =~ ^https:// ]]; then
        log_warning "$description 使用非加密協議: $url"
    fi
    
    # 檢查是否為已知安全域名
    case "$url" in
        https://github.com/*|https://api.github.com/*|https://raw.githubusercontent.com/*)
            return 0
            ;;
        https://httpbin.org/*)
            log_warning "$description 指向測試網站，僅供開發使用"
            return 0
            ;;
        *)
            log_warning "$description 指向未知域名，請確認安全性: $url"
            return 0
            ;;
    esac
}

# 增強的 GitHub API 呼叫函數
get_github_latest_release() {
    local repo="$1"
    local field="${2:-tag_name}"
    local max_retries="${3:-3}"
    
    # 檢查必要參數
    if [ -z "$repo" ]; then
        log_error "get_github_latest_release: 缺少 repository 參數"
        return 1
    fi
    
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    
    # 驗證構建的 API URL
    if ! validate_url "$api_url" "GitHub API URL"; then
        log_error "無效的 GitHub API URL: $api_url"
        return 1
    fi
    
    local retry_count=0
    local result=""
    
    while [ $retry_count -lt $max_retries ]; do
        retry_count=$((retry_count + 1))
        
        log_info "取得 $repo 最新版本 (第 $retry_count 次嘗試)..."
        
        # 使用增強的 curl 呼叫，包含 User-Agent 和錯誤處理
        result=$(curl -s --max-time 30 --connect-timeout 10 \
            -H "Accept: application/vnd.github.v3+json" \
            -H "User-Agent: dotfiles-installer/1.0 (https://github.com/user/dotfiles)" \
            "$api_url" 2>/dev/null)
        
        # 檢查 curl 是否成功
        if [ $? -eq 0 ] && [ -n "$result" ]; then
            # 嘗試解析 JSON 回應
            local parsed_value=""
            
            # 優先使用 jq 如果可用
            if command -v jq &> /dev/null; then
                parsed_value=$(echo "$result" | jq -r ".$field // empty" 2>/dev/null)
            else
                # 備用：使用 grep 和 sed 解析
                parsed_value=$(echo "$result" | grep "\"$field\":" | sed -E "s/.*\"$field\":[[:space:]]*\"([^\"]+)\".*/\\1/" | head -n1)
            fi
            
            # 檢查是否獲得有效結果
            if [ -n "$parsed_value" ] && [ "$parsed_value" != "null" ]; then
                echo "$parsed_value"
                return 0
            else
                log_warning "第 $retry_count 次 API 呼叫返回無效資料"
            fi
        else
            log_warning "第 $retry_count 次 GitHub API 呼叫失敗"
        fi
        
        # 如果不是最後一次嘗試，等待後重試
        if [ $retry_count -lt $max_retries ]; then
            local wait_time=$((retry_count * 2))
            log_info "等待 $wait_time 秒後重試..."
            sleep $wait_time
        fi
    done
    
    log_error "無法從 GitHub API 取得 $repo 的 $field（已重試 $max_retries 次）"
    return 1
}

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

# 檔案完整性驗證函數
verify_download() {
    local file="$1"
    local expected_hash="$2"
    local description="${3:-檔案}"
    
    # 檢查輸入參數
    if [ -z "$file" ] || [ -z "$expected_hash" ]; then
        log_error "verify_download: 缺少必要參數"
        return 1
    fi
    
    # 檢查檔案是否存在
    if [ ! -f "$file" ]; then
        log_error "驗證失敗: $description 不存在"
        return 1
    fi
    
    local actual_hash
    
    # 選擇可用的雜湊工具
    if command -v sha256sum &> /dev/null; then
        actual_hash=$(sha256sum "$file" | cut -d' ' -f1)
    elif command -v shasum &> /dev/null; then
        actual_hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
    else
        log_warning "無法驗證 $description 完整性：缺少 sha256sum 或 shasum"
        # 在沒有雜湊工具的情況下，檢查檔案大小是否合理
        local file_size
        file_size=$(wc -c < "$file" 2>/dev/null || echo "0")
        if [ "$file_size" -lt 1000 ]; then
            log_error "$description 檔案過小，可能下載不完整"
            return 1
        fi
        log_warning "跳過 $description 完整性驗證（無雜湊工具）"
        return 0
    fi
    
    # 驗證雜湊值
    if [ "$actual_hash" = "$expected_hash" ]; then
        log_success "$description 完整性驗證通過"
        return 0
    else
        log_error "$description 完整性驗證失敗"
        log_error "預期: $expected_hash"
        log_error "實際: $actual_hash"
        
        # 檢查是否跳過雜湊驗證（用於測試或緊急情況）
        if [ "$SKIP_HASH_CHECK" = "true" ]; then
            log_warning "跳過雜湊驗證（SKIP_HASH_CHECK=true）"
            return 0
        else
            log_error "設定 SKIP_HASH_CHECK=true 可跳過驗證（不建議）"
            return 1
        fi
    fi
}

# 安全的套件安裝函數（避免 eval 代碼注入）
install_package() {
    local package_name="$1"
    local description="${2:-$package_name}"
    
    # 檢查必要參數
    if [ -z "$package_name" ]; then
        log_error "install_package: 缺少套件名稱"
        return 1
    fi
    
    # 檢查是否有可用的包管理器
    if [ "$PKG_MANAGER" = "none" ]; then
        log_error "無可用的包管理器來安裝 $description"
        return 1
    fi
    
    log_info "使用 $PKG_MANAGER 安裝 $description..."
    
    # 根據包管理器類型使用相應的安裝命令
    case "$PKG_MANAGER" in
        "brew")
            if brew install "$package_name"; then
                log_success "$description 通過 Homebrew 安裝成功"
                return 0
            else
                log_error "$description 通過 Homebrew 安裝失敗"
                return 1
            fi
            ;;
        "apt")
            if sudo apt-get update && sudo apt-get install -y "$package_name"; then
                log_success "$description 通過 apt 安裝成功"
                return 0
            else
                log_error "$description 通過 apt 安裝失敗"
                return 1
            fi
            ;;
        "yum")
            if sudo yum install -y "$package_name"; then
                log_success "$description 通過 yum 安裝成功"
                return 0
            else
                log_error "$description 通過 yum 安裝失敗"
                return 1
            fi
            ;;
        "dnf")
            if sudo dnf install -y "$package_name"; then
                log_success "$description 通過 dnf 安裝成功"
                return 0
            else
                log_error "$description 通過 dnf 安裝失敗"
                return 1
            fi
            ;;
        "pacman")
            if sudo pacman -S --noconfirm "$package_name"; then
                log_success "$description 通過 pacman 安裝成功"
                return 0
            else
                log_error "$description 通過 pacman 安裝失敗"
                return 1
            fi
            ;;
        *)
            log_error "不支援的包管理器: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# 安全的路徑操作函數
safe_remove_directory() {
    local dir_path="$1"
    local description="${2:-目錄}"
    
    # 安全檢查
    if [ -z "$dir_path" ]; then
        log_error "safe_remove_directory: 缺少目錄路徑"
        return 1
    fi
    
    # 防止刪除根目錄或重要系統目錄
    case "$dir_path" in
        "/" | "/bin" | "/sbin" | "/usr" | "/var" | "/etc" | "/home" | "$HOME")
            log_error "拒絕刪除重要系統目錄: $dir_path"
            return 1
            ;;
        "")
            log_error "目錄路徑為空，拒絕執行 rm"
            return 1
            ;;
    esac
    
    # 檢查路徑是否包含危險字符
    if [[ "$dir_path" == *".."* ]] || [[ "$dir_path" == *"*"* ]]; then
        log_error "目錄路徑包含危險字符: $dir_path"
        return 1
    fi
    
    # 檢查目錄是否存在且為目錄
    if [ ! -d "$dir_path" ]; then
        log_warning "$description 不存在或不是目錄: $dir_path"
        return 0
    fi
    
    # 執行安全的刪除操作
    log_info "清理 $description: $dir_path"
    if rm -rf "$dir_path"; then
        log_success "$description 清理完成"
        return 0
    else
        log_error "$description 清理失敗"
        return 1
    fi
}

# 統一的 PATH 更新管理函數
add_to_path() {
    local bin_dir="$1"
    local description="${2:-$bin_dir}"
    
    # 檢查必要參數
    if [ -z "$bin_dir" ]; then
        log_error "add_to_path: 缺少目錄路徑"
        return 1
    fi
    
    # 檢查目錄是否存在
    if [ ! -d "$bin_dir" ]; then
        log_error "目錄不存在: $bin_dir"
        return 1
    fi
    
    # 檢查 PATH 是否已包含此目錄
    if [[ ":$PATH:" == *":$bin_dir:"* ]]; then
        log_info "$description 已在 PATH 中"
        return 0
    fi
    
    log_info "將 $description 加入 PATH"
    
    # 選擇適當的 shell 配置檔案
    local shell_config=""
    if [ -n "$BASH_VERSION" ]; then
        shell_config="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.profile"
    fi
    
    # 檢查配置檔案是否存在
    if [ ! -f "$shell_config" ]; then
        touch "$shell_config"
    fi
    
    # 檢查是否已經添加過此路徑
    if ! grep -q "export PATH.*$bin_dir" "$shell_config" 2>/dev/null; then
        echo "" >> "$shell_config"
        echo "# Added by dotfiles installer" >> "$shell_config"
        echo "export PATH=\"$bin_dir:\$PATH\"" >> "$shell_config"
        log_success "已將 $description 添加到 $shell_config"
    else
        log_info "$description 已存在於 $shell_config 中"
    fi
    
    # 立即更新當前會話的 PATH
    export PATH="$bin_dir:$PATH"
    
    log_info "PATH 已更新，請重啟終端或執行 'source $shell_config'"
    return 0
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

# 檢查 neovim 版本是否符合要求
check_neovim_version() {
    if ! command -v nvim &> /dev/null; then
        return 1  # neovim 未安裝
    fi
    
    local version_output
    version_output=$(nvim --version 2>/dev/null | head -n1)
    
    if [ -z "$version_output" ]; then
        log_warning "無法獲取 neovim 版本信息"
        return 1
    fi
    
    # 提取版本號 (例如: NVIM v0.9.1 -> 0.9.1)
    local version
    version=$(echo "$version_output" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/v//')
    
    if [ -z "$version" ]; then
        log_warning "無法解析 neovim 版本: $version_output"
        return 1
    fi
    
    # 檢查是否為 0.8.0 以上版本 (NvChad 最低要求)
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    
    if [ "$major" -gt 0 ] || ([ "$major" -eq 0 ] && [ "$minor" -ge 8 ]); then
        log_info "neovim 版本: $version (符合 NvChad 要求)"
        return 0
    else
        log_warning "neovim 版本過舊: $version (需要 0.8.0+)"
        return 1
    fi
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

# 使用 AppImage 安裝 neovim (無需管理員權限)
install_neovim_appimage() {
    log_info "使用 AppImage 安裝 neovim..."
    
    # 檢查系統是否支援 AppImage (僅 Linux)
    if [ "$SYSTEM" != "linux" ]; then
        log_error "AppImage 安裝僅支援 Linux 系統"
        return 1
    fi
    
    # 創建本地 bin 目錄
    local local_bin="$HOME/.local/bin"
    mkdir -p "$local_bin"
    
    # 下載最新的 neovim AppImage
    local appimage_url="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
    local appimage_path="$local_bin/nvim.appimage"
    local nvim_path="$local_bin/nvim"
    
    log_info "下載 neovim AppImage..."
    
    # 檢查網路連線
    if ! curl -s --connect-timeout 5 --max-time 10 "https://api.github.com/repos/neovim/neovim" >/dev/null; then
        log_error "無法連接到 GitHub，請檢查網路連線"
        return 1
    fi
    
    # 使用更強韌的下載邏輯
    local download_attempts=0
    local max_attempts=3
    
    while [ $download_attempts -lt $max_attempts ]; do
        download_attempts=$((download_attempts + 1))
        log_info "嘗試下載 neovim AppImage (第 $download_attempts 次)..."
        
        if curl -fLo "$appimage_path" --connect-timeout 30 --max-time 300 --retry 2 "$appimage_url"; then
            log_success "neovim AppImage 下載成功"
            break
        else
            log_warning "下載失敗 (第 $download_attempts 次)"
            if [ $download_attempts -eq $max_attempts ]; then
                log_error "neovim AppImage 下載失敗，已重試 $max_attempts 次"
                return 1
            fi
            sleep 2
        fi
    done
    
    # 設定執行權限 (755: 擁有者可讀寫執行，群組和其他使用者可讀執行)
    chmod 755 "$appimage_path"
    
    # 創建符號連結
    if [ -e "$nvim_path" ]; then
        rm -f "$nvim_path"
    fi
    ln -s "$appimage_path" "$nvim_path"
    
    # 將 neovim 加入 PATH
    add_to_path "$local_bin" "neovim 執行檔目錄"
    
    # 驗證安裝
    if command -v nvim &> /dev/null && check_neovim_version; then
        log_success "neovim AppImage 安裝成功"
        return 0
    else
        log_error "neovim AppImage 安裝驗證失敗"
        return 1
    fi
}

# 從源碼編譯安裝 neovim (最後選項)
install_neovim_from_source() {
    log_info "從源碼編譯安裝 neovim..."
    
    # 檢查編譯依賴
    local build_deps=()
    local missing_deps=()
    
    case "$SYSTEM" in
        "linux")
            build_deps=("git" "make" "cmake" "gcc" "g++")
            ;;
        "macos")
            build_deps=("git" "make" "cmake")
            if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
                log_error "需要安裝 Xcode Command Line Tools: xcode-select --install"
                return 1
            fi
            ;;
        *)
            log_error "不支援在此系統上從源碼編譯"
            return 1
            ;;
    esac
    
    # 檢查編譯依賴是否存在
    for dep in "${build_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "缺少編譯依賴: ${missing_deps[*]}"
        log_info "請先安裝這些工具後重試"
        return 1
    fi
    
    # 建立臨時編譯目錄，使用更安全的隨機名稱
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local random_suffix=$(od -An -N4 -tx4 /dev/urandom 2>/dev/null | tr -d ' ' || echo "$RANDOM")
    local build_dir="/tmp/neovim-build-${timestamp}-${random_suffix}"
    local install_prefix="$HOME/.local"
    
    # 檢查臨時目錄是否已存在（避免衝突）
    if [ -e "$build_dir" ]; then
        log_error "臨時目錄已存在，可能有其他安裝程序正在執行: $build_dir"
        return 1
    fi
    
    mkdir -p "$build_dir"
    cd "$build_dir" || {
        log_error "無法進入編譯目錄: $build_dir"
        return 1
    }
    
    # 下載 neovim 源碼
    log_info "下載 neovim 源碼..."
    if ! git clone --depth 1 --branch stable https://github.com/neovim/neovim.git; then
        log_error "neovim 源碼下載失敗"
        safe_remove_directory "$build_dir" "neovim 編譯目錄"
        return 1
    fi
    
    cd neovim || {
        log_error "無法進入 neovim 源碼目錄"
        safe_remove_directory "$build_dir" "neovim 編譯目錄"
        return 1
    }
    
    # 編譯和安裝
    log_info "開始編譯 neovim (這可能需要幾分鐘)..."
    if ! make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$install_prefix"; then
        log_error "neovim 編譯失敗"
        safe_remove_directory "$build_dir" "neovim 編譯目錄"
        return 1
    fi
    
    log_info "安裝 neovim..."
    if ! make install; then
        log_error "neovim 安裝失敗"
        safe_remove_directory "$build_dir" "neovim 編譯目錄"
        return 1
    fi
    
    # 清理編譯目錄
    safe_remove_directory "$build_dir" "neovim 編譯目錄"
    
    # 將 neovim 加入 PATH
    local local_bin="$install_prefix/bin"
    add_to_path "$local_bin" "neovim 執行檔目錄"
    
    # 驗證安裝
    if command -v nvim &> /dev/null && check_neovim_version; then
        log_success "neovim 源碼編譯安裝成功"
        return 0
    else
        log_error "neovim 源碼編譯安裝驗證失敗"
        return 1
    fi
}

# 使用預編譯二進制安裝 ripgrep (無需管理員權限)
install_ripgrep_binary() {
    log_info "使用預編譯二進制安裝 ripgrep..."
    
    # 創建本地 bin 目錄
    local local_bin="$HOME/.local/bin"
    mkdir -p "$local_bin"
    
    # 檢測系統架構
    local arch
    case "$(uname -m)" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        arm64|aarch64)
            arch="aarch64"
            ;;
        armv7l)
            arch="arm"
            ;;
        *)
            log_error "不支援的系統架構: $(uname -m)"
            return 1
            ;;
    esac
    
    # 設定下載 URL 和檔名
    local base_url="https://github.com/BurntSushi/ripgrep/releases/latest/download"
    local filename
    local extract_cmd
    
    case "$SYSTEM" in
        "linux")
            filename="ripgrep-*-${arch}-unknown-linux-musl.tar.gz"
            extract_cmd="tar -xzf"
            ;;
        "macos")
            if [ "$arch" = "aarch64" ]; then
                arch="aarch64"
            fi
            filename="ripgrep-*-${arch}-apple-darwin.tar.gz"
            extract_cmd="tar -xzf"
            ;;
        *)
            log_error "不支援的作業系統: $SYSTEM"
            return 1
            ;;
    esac
    
    # 取得最新版本號
    local latest_version
    latest_version=$(get_github_latest_release "BurntSushi/ripgrep" "tag_name")
    
    if [ -z "$latest_version" ]; then
        log_error "無法取得 ripgrep 最新版本信息"
        return 1
    fi
    
    log_success "找到 ripgrep 最新版本: $latest_version"
    
    # 建立完整檔名和 URL
    local actual_filename
    case "$SYSTEM" in
        "linux")
            actual_filename="ripgrep-${latest_version}-${arch}-unknown-linux-musl.tar.gz"
            ;;
        "macos")
            actual_filename="ripgrep-${latest_version}-${arch}-apple-darwin.tar.gz"
            ;;
    esac
    
    local download_url="$base_url/$actual_filename"
    local temp_dir="/tmp/ripgrep-install-$$"
    
    mkdir -p "$temp_dir"
    cd "$temp_dir" || {
        log_error "無法進入臨時目錄: $temp_dir"
        return 1
    }
    
    # 下載 ripgrep
    log_info "下載 ripgrep $latest_version..."
    if ! curl -fLo "$actual_filename" --connect-timeout 30 --max-time 120 --retry 3 "$download_url"; then
        log_error "ripgrep 下載失敗"
        safe_remove_directory "$temp_dir" "ripgrep 安裝臨時目錄"
        return 1
    fi
    
    # 解壓縮
    log_info "解壓縮 ripgrep..."
    if ! $extract_cmd "$actual_filename"; then
        log_error "ripgrep 解壓縮失敗"
        safe_remove_directory "$temp_dir" "ripgrep 安裝臨時目錄"
        return 1
    fi
    
    # 尋找並複製 rg 執行檔
    local rg_binary
    rg_binary=$(find . -name "rg" -type f | head -n1)
    
    if [ -z "$rg_binary" ]; then
        log_error "找不到 rg 執行檔"
        safe_remove_directory "$temp_dir" "ripgrep 安裝臨時目錄"
        return 1
    fi
    
    # 複製到本地 bin 目錄
    cp "$rg_binary" "$local_bin/rg"
    chmod 755 "$local_bin/rg"
    
    # 清理臨時檔案
    safe_remove_directory "$temp_dir" "ripgrep 安裝臨時目錄"
    
    # 將 ripgrep 加入 PATH
    add_to_path "$local_bin" "ripgrep 執行檔目錄"
    
    # 驗證安裝
    if command -v rg &> /dev/null; then
        local rg_version
        rg_version=$(rg --version | head -n1)
        log_success "ripgrep 預編譯二進制安裝成功: $rg_version"
        return 0
    else
        log_error "ripgrep 安裝驗證失敗"
        return 1
    fi
}

# 主要 ripgrep 安裝函數
install_ripgrep() {
    log_info "檢查和安裝 ripgrep..."
    
    # 如果已安裝 ripgrep，跳過安裝
    if command -v rg &> /dev/null; then
        log_success "ripgrep 已安裝"
        return 0
    fi
    
    log_info "需要安裝 ripgrep"
    
    # 根據系統和權限選擇安裝方法
    case "$SYSTEM" in
        "macos")
            if [ "$PKG_MANAGER" = "brew" ]; then
                log_info "使用 Homebrew 安裝 ripgrep..."
                if install_package "ripgrep" "ripgrep"; then
                    return 0
                else
                    log_warning "Homebrew 安裝失敗，嘗試預編譯二進制..."
                    if install_ripgrep_binary; then
                        return 0
                    fi
                fi
            else
                log_warning "macOS 系統建議先安裝 Homebrew"
                log_info "嘗試使用預編譯二進制安裝..."
                if install_ripgrep_binary; then
                    return 0
                fi
            fi
            ;;
        "linux")
            # 嘗試包管理器安裝
            if [ "$PKG_MANAGER" != "none" ]; then
                log_info "使用 $PKG_MANAGER 安裝 ripgrep..."
                
                local pkg_name="ripgrep"
                if install_package "$pkg_name" "ripgrep"; then
                    return 0
                else
                    log_warning "$PKG_MANAGER 安裝失敗，嘗試預編譯二進制..."
                    if install_ripgrep_binary; then
                        return 0
                    fi
                fi
            else
                # 沒有包管理器，直接嘗試預編譯二進制
                log_info "未找到包管理器，嘗試預編譯二進制安裝..."
                if install_ripgrep_binary; then
                    return 0
                fi
            fi
            ;;
        *)
            log_error "不支援的作業系統: $SYSTEM"
            return 1
            ;;
    esac
    
    # 最後嘗試 cargo 安裝 (如果有 Rust)
    if command -v cargo &> /dev/null; then
        log_info "嘗試使用 cargo 安裝 ripgrep..."
        if cargo install ripgrep; then
            log_success "ripgrep 通過 cargo 安裝成功"
            return 0
        fi
    fi
    
    log_error "所有 ripgrep 安裝方法都失敗了"
    log_info "請手動安裝 ripgrep 後重新執行腳本"
    return 1
}

# 主要 neovim 安裝函數
install_neovim() {
    log_info "檢查和安裝 neovim..."
    
    # 如果已有符合版本要求的 neovim，跳過安裝
    if check_neovim_version; then
        log_success "neovim 已安裝且版本符合要求"
        return 0
    fi
    
    log_info "需要安裝或升級 neovim"
    
    # 根據系統和權限選擇安裝方法
    case "$SYSTEM" in
        "macos")
            if [ "$PKG_MANAGER" = "brew" ]; then
                log_info "使用 Homebrew 安裝 neovim..."
                if install_package "neovim" "neovim"; then
                    return 0
                else
                    log_warning "Homebrew 安裝失敗，嘗試源碼編譯..."
                    if install_neovim_from_source; then
                        return 0
                    fi
                fi
            else
                log_warning "macOS 系統建議先安裝 Homebrew"
                echo "安裝命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                if install_neovim_from_source; then
                    return 0
                fi
            fi
            ;;
        "linux")
            # 嘗試包管理器安裝
            if [ "$PKG_MANAGER" != "none" ]; then
                log_info "使用 $PKG_MANAGER 安裝 neovim..."
                
                # 針對不同包管理器的 neovim 包名
                local pkg_name="neovim"
                case "$PKG_MANAGER" in
                    "apt")
                        # Ubuntu/Debian 可能需要 ppa 來獲取新版本
                        if ! install_package "$pkg_name" "neovim"; then
                            log_warning "$PKG_MANAGER 安裝失敗，嘗試使用 AppImage..."
                            if install_neovim_appimage; then
                                return 0
                            fi
                        elif ! check_neovim_version; then
                            log_warning "系統 neovim 版本過舊，嘗試使用 AppImage..."
                            if install_neovim_appimage; then
                                return 0
                            fi
                        else
                            log_success "neovim 通過 $PKG_MANAGER 安裝成功"
                            return 0
                        fi
                        ;;
                    *)
                        if install_package "$pkg_name" "neovim"; then
                            if check_neovim_version; then
                                log_success "neovim 通過 $PKG_MANAGER 安裝成功"
                                return 0
                            else
                                log_warning "包管理器安裝的版本過舊，嘗試 AppImage..."
                                if install_neovim_appimage; then
                                    return 0
                                fi
                            fi
                        else
                            log_warning "$PKG_MANAGER 安裝失敗，嘗試 AppImage..."
                            if install_neovim_appimage; then
                                return 0
                            fi
                        fi
                        ;;
                esac
            else
                # 沒有包管理器，直接嘗試 AppImage
                log_info "未找到包管理器，嘗試 AppImage 安裝..."
                if install_neovim_appimage; then
                    return 0
                fi
            fi
            
            # 如果 AppImage 失敗，嘗試源碼編譯
            log_warning "AppImage 安裝失敗，嘗試源碼編譯..."
            if install_neovim_from_source; then
                return 0
            fi
            ;;
        *)
            log_error "不支援的作業系統: $SYSTEM"
            return 1
            ;;
    esac
    
    log_error "所有 neovim 安裝方法都失敗了"
    log_info "請手動安裝 neovim 0.8.0+ 版本後重新執行腳本"
    return 1
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
    # 逐一安裝缺失的程式（避免安全風險）
    local install_success=true
    for dep in "${missing_deps[@]}"; do
        if ! install_package "$dep" "$dep"; then
            install_success=false
            break
        fi
    done
    
    if [ "$install_success" = "true" ]; then
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
    
    local basic_tools=("vim" "tmux")
    local missing_tools=()
    
    # 檢查基本工具
    for tool in "${basic_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_warning "缺少基本工具: ${missing_tools[*]}"
        
        # 如果啟用自動安裝選項
        if [ "$AUTO_INSTALL_DEPS" = "true" ]; then
            if install_dependencies "${missing_tools[@]}"; then
                log_success "基本工具已安裝"
            else
                log_error "無法自動安裝缺失工具，請手動安裝後重試"
                return 1
            fi
        else
            log_error "請先安裝這些工具再執行安裝腳本"
            log_info "或使用 --install-deps 選項自動安裝"
            return 1
        fi
    else
        log_success "基本工具已安裝"
    fi
    
    # 檢查和安裝 neovim (核心功能)
    log_info "檢查 neovim (主要編輯器)..."
    if [ "$AUTO_INSTALL_DEPS" = "true" ] || [ "$INSTALL_NEOVIM" = "true" ]; then
        if ! install_neovim; then
            log_warning "neovim 安裝失敗，但可以繼續安裝其他配置"
            log_info "建議手動安裝 neovim 0.8.0+ 以獲得完整功能"
        fi
    else
        if ! check_neovim_version; then
            log_warning "neovim 未安裝或版本過舊 (需要 0.8.0+)"
            log_info "使用 --install-deps 選項可自動安裝 neovim"
            log_info "nvim 是主要編輯器，強烈建議安裝"
        else
            log_success "neovim 已安裝且版本符合要求"
        fi
    fi
    
    # 檢查和安裝 ripgrep (NvChad 重要依賴)
    log_info "檢查 ripgrep (搜尋工具)..."
    if [ "$AUTO_INSTALL_DEPS" = "true" ]; then
        if ! install_ripgrep; then
            log_warning "ripgrep 安裝失敗，但可以繼續安裝其他配置"
            log_info "ripgrep 提供更好的搜尋體驗，建議手動安裝"
        fi
    else
        if ! command -v rg &> /dev/null; then
            log_warning "ripgrep 未安裝 (NvChad 強烈建議使用)"
            log_info "使用 --install-deps 選項可自動安裝 ripgrep"
            log_info "ripgrep 提供快速的文件內容搜尋功能"
        else
            log_success "ripgrep 已安裝"
        fi
    fi
    
    # 檢查 Node.js (GitHub Copilot 必需)
    log_info "檢查 Node.js (GitHub Copilot 依賴)..."
    if command -v node &> /dev/null; then
        local node_version
        node_version=$(node --version 2>/dev/null | sed 's/v//')
        local major_version
        major_version=$(echo "$node_version" | cut -d'.' -f1)
        
        if [ -n "$major_version" ] && [ "$major_version" -ge 16 ]; then
            log_success "Node.js 已安裝：v$node_version (符合 Copilot 要求)"
        else
            log_warning "Node.js 版本過舊：v$node_version (Copilot 需要 16.0+)"
            log_info "請手動安裝 Node.js 16.0+ 以使用 GitHub Copilot 功能"
        fi
    else
        log_warning "Node.js 未安裝 (GitHub Copilot 功能需要)"
        log_info "請安裝 Node.js 16.0+ 以使用 AI 智慧補全功能"
        log_info "安裝方式：https://nodejs.org/ 或使用包管理器"
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

# 安裝 Nerd Fonts (NvChad 必需)
install_nerd_fonts() {
    log_info "檢查 Nerd Fonts..."
    
    # 檢查是否已安裝 Nerd Fonts
    if ls "$HOME/Library/Fonts/"*NerdFont* &>/dev/null; then
        log_success "Nerd Fonts 已安裝"
        return 0
    fi
    
    if [ "$PKG_MANAGER" = "brew" ]; then
        log_info "安裝 Nerd Fonts (NvChad 必需的圖示字體)..."
        
        # 安裝 FiraCode 和 JetBrains Mono Nerd Font
        if brew install font-fira-code-nerd-font font-jetbrains-mono-nerd-font; then
            log_success "Nerd Fonts 安裝完成"
            
            # 設定 macOS 字體平滑化
            if defaults write -g AppleFontSmoothing -int 1 2>/dev/null; then
                log_info "已啟用 macOS 字體平滑化"
            fi
            
            log_info "請在終端機設定中選擇以下字體之一："
            echo "  - FiraCode Nerd Font"
            echo "  - JetBrains Mono Nerd Font"
            
            return 0
        else
            log_error "Nerd Fonts 安裝失敗"
            return 1
        fi
    else
        log_warning "請手動安裝 Nerd Fonts 以正確顯示 NvChad 圖示："
        echo "1. 訪問 https://www.nerdfonts.com/font-downloads"
        echo "2. 下載並安裝 FiraCode Nerd Font 或 JetBrains Mono Nerd Font"
        echo "3. 在終端機設定中選擇 Nerd Font"
        return 1
    fi
}

# 安裝 nvim 設定 (完整 NvChad 配置含自定義功能)
install_nvim() {
    # 確保 neovim 可用
    if ! check_neovim_version; then
        log_info "嘗試安裝 neovim..."
        if ! install_neovim; then
            log_error "neovim 安裝失敗，無法安裝 nvim 配置"
            log_info "請手動安裝 neovim 0.8.0+ 後重新執行"
            return 1
        fi
    fi
    
    # 安裝 Nerd Fonts (NvChad 必需)
    if ! install_nerd_fonts; then
        log_warning "Nerd Fonts 安裝失敗，NvChad 可能無法正確顯示圖示"
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
                    safe_remove_directory "$temp_dir" "ripgrep 安裝臨時目錄"
                    return 1
                fi
                safe_remove_directory "$temp_dir" "ripgrep 安裝臨時目錄"
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
    echo "  --install-deps      自動安裝缺失的相依程式 (包含 neovim)"
    echo "  --install-neovim    強制安裝 neovim (支援多種方式)"
    echo "  --check-only        僅檢查相依程式狀況，不安裝設定"
    echo ""
    echo "安裝方式說明:"
    echo "  neovim 安裝優先順序:"
    echo "    1. 包管理器 (brew, apt, yum, dnf, pacman)"
    echo "    2. AppImage (Linux 無權限時)"
    echo "    3. 源碼編譯 (最後選項)"
    echo ""
    echo "範例:"
    echo "  $0                      # 安裝所有設定"
    echo "  $0 --vim                # 僅安裝 vim 設定"
    echo "  $0 --install-deps       # 自動安裝所有缺失程式並安裝設定"
    echo "  $0 --install-neovim     # 強制安裝 neovim"
    echo "  $0 --nvim --install-neovim # 安裝 neovim 並配置"
    echo "  $0 --check-only         # 僅檢查相依程式狀況"
}

# 主程式
main() {
    log_info "開始安裝 dotfiles..."
    
    # 檢查腳本權限
    check_script_permissions
    
    # 切換到腳本所在目錄，處理符號連結
    local script_dir
    if [ -L "${BASH_SOURCE[0]}" ]; then
        # 如果腳本是符號連結，獲取真實路徑
        script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
    else
        script_dir=$(dirname "${BASH_SOURCE[0]}")
    fi
    
    # 檢查目錄是否存在並可訪問
    if [ ! -d "$script_dir" ]; then
        log_error "無法找到腳本目錄: $script_dir"
        exit 1
    fi
    
    cd "$script_dir" || {
        log_error "無法切換到腳本目錄: $script_dir"
        exit 1
    }
    
    # 解析命令列參數
    local install_vim=false
    local install_tmux_flag=false
    local install_nvim_flag=false
    local install_all=true
    local check_only=false
    AUTO_INSTALL_DEPS=false  # 全域變數
    INSTALL_NEOVIM=false     # 強制安裝 neovim 標誌
    
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
            --install-neovim)
                INSTALL_NEOVIM=true
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
    if ! check_dependencies; then
        log_error "必要工具檢查失敗，安裝中止"
        exit 1
    fi
    
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
        echo "4. 在終端機設定中選擇 Nerd Font (如 FiraCode Nerd Font)"
        echo "5. 開啟 nvim，NvChad 會自動安裝所有 plugins"
        echo "6. GitHub Copilot 設定："
        echo "   - 執行 <leader>coa 進行 GitHub 認證登入"
        echo "   - 使用 <leader>cos 檢查 Copilot 狀態"
        echo "   - 使用 <leader>coe/<leader>cod 啟用/停用 Copilot"
        echo "7. 測試功能："
        echo "   - 智能剪貼簿：選取代碼後按 <leader>cpr"
        echo "   - Claude Code：按 <leader>cc 開啟 AI 助手"
        echo "   - GitHub Copilot：編輯程式碼時自動顯示 AI 建議"
        echo "8. 參考 ~/dotfiles/nvim/CLAUDE.md 了解完整功能"
    fi
}

# 執行主程式
main "$@"