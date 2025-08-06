-- 傳輸管理模組
-- 負責多種剪貼板傳輸方式的統一管理和路由

local M = {}

-- 傳輸介面定義
local ITransport = {}
function ITransport:new() error("Interface cannot be instantiated") end
function ITransport:is_available() error("Must implement is_available method") end
function ITransport:send(content) error("Must implement send method") end
function ITransport:get_priority() error("Must implement get_priority method") end
function ITransport:get_name() error("Must implement get_name method") end

-- 已註冊的傳輸方式
local transports = {}

-- OSC 52 傳輸實現
local OSC52Transport = {}
OSC52Transport.__index = OSC52Transport
setmetatable(OSC52Transport, {__index = ITransport})

function OSC52Transport:new()
    local instance = {
        name = "osc52",
        priority = 1,
        max_size = 32768
    }
    setmetatable(instance, self)
    return instance
end

function OSC52Transport:is_available()
    local config = require('utils.clipboard.config')
    if not config.get('enable_osc52') then
        return false, "OSC 52 disabled in config"
    end
    
    local term_program = os.getenv('TERM_PROGRAM') or ''
    local term = os.getenv('TERM') or ''
    
    -- 支援的終端列表
    local supported_terminals = {
        'iTerm.app', 'Apple_Terminal', 'tmux', 'alacritty', 'kitty', 'wezterm'
    }
    
    for _, supported in ipairs(supported_terminals) do
        if term_program:match(supported) or term:match(supported) then
            return true, "Terminal supports OSC 52"
        end
    end
    
    return false, "Terminal does not support OSC 52"
end

function OSC52Transport:send(content)
    if #content > self.max_size then
        return false, string.format("Content too large for OSC 52: %d > %d", #content, self.max_size)
    end
    
    -- Base64 編碼
    local base64_content = vim.base64.encode(content)
    
    -- 安全檢查：清理控制字符
    base64_content = base64_content:gsub('[\000-\031\127-\255]', '')
    base64_content = base64_content:gsub('\027', '')  -- 移除 ESC
    base64_content = base64_content:gsub('\007', '')  -- 移除 BEL
    
    -- 構建 OSC 52 序列
    local osc_seq = string.format('\027]52;c;%s\007', base64_content)
    
    -- 發送序列
    local success, err = pcall(function()
        io.write(osc_seq)
        io.flush()
    end)
    
    if success then
        return true, "OSC 52 sent successfully"
    else
        return false, "OSC 52 send failed: " .. tostring(err)
    end
end

function OSC52Transport:get_priority() return self.priority end
function OSC52Transport:get_name() return self.name end

-- 系統剪貼板傳輸實現
local SystemTransport = {}
SystemTransport.__index = SystemTransport
setmetatable(SystemTransport, {__index = ITransport})

function SystemTransport:new()
    local instance = {
        name = "system",
        priority = 2
    }
    setmetatable(instance, self)
    return instance
end

function SystemTransport:is_available()
    local os_name = vim.uv.os_uname().sysname
    
    local commands = {
        Darwin = {"pbcopy"},
        Linux = {"xclip", "xsel", "wl-copy"},
        Windows = {"clip"}
    }
    
    local os_commands = commands[os_name] or {}
    
    for _, cmd in ipairs(os_commands) do
        if vim.fn.executable(cmd) == 1 then
            self.command = cmd
            return true, "System clipboard available via " .. cmd
        end
    end
    
    return false, "No system clipboard command available"
end

function SystemTransport:send(content)
    if not self.command then
        local available, reason = self:is_available()
        if not available then
            return false, reason
        end
    end
    
    -- 使用現代 vim.system API
    if vim.system then
        local result = vim.system({self.command}, {
            stdin = content,
            timeout = 5000
        })
        
        if result.code == 0 then
            return true, "System clipboard updated successfully"
        else
            return false, string.format("System clipboard failed: %s", result.stderr or "Unknown error")
        end
    else
        -- 回退到 vim.fn.system
        local result = vim.fn.system(self.command, content)
        local exit_code = vim.v.shell_error
        
        if exit_code == 0 then
            return true, "System clipboard updated successfully"
        else
            return false, string.format("System clipboard failed with code: %d", exit_code)
        end
    end
end

function SystemTransport:get_priority() return self.priority end
function SystemTransport:get_name() return self.name end

-- Vim 暫存器傳輸實現
local VimRegisterTransport = {}
VimRegisterTransport.__index = VimRegisterTransport
setmetatable(VimRegisterTransport, {__index = ITransport})

function VimRegisterTransport:new()
    local instance = {
        name = "vim_register",
        priority = 3
    }
    setmetatable(instance, self)
    return instance
end

function VimRegisterTransport:is_available()
    return true, "Vim registers always available"
end

function VimRegisterTransport:send(content)
    local success, err = pcall(function()
        vim.fn.setreg('+', content)  -- 系統剪貼板
        vim.fn.setreg('"', content)  -- 無名暫存器
        vim.fn.setreg('0', content)  -- 複製暫存器
    end)
    
    if success then
        return true, "Content copied to Vim registers"
    else
        return false, "Failed to copy to Vim registers: " .. tostring(err)
    end
end

function VimRegisterTransport:get_priority() return self.priority end
function VimRegisterTransport:get_name() return self.name end

-- 註冊預設傳輸方式
transports["osc52"] = OSC52Transport:new()
transports["system"] = SystemTransport:new()
transports["vim_register"] = VimRegisterTransport:new()

-- 主要傳輸管理功能
function M.send_content(content)
    local config = require('utils.clipboard.config')
    local transport_priority = config.get('transport_priority') or {"osc52", "system", "vim_register"}
    
    local results = {}
    local success_count = 0
    local primary_success = false
    
    -- 按優先級嘗試傳輸
    for _, transport_name in ipairs(transport_priority) do
        local transport = transports[transport_name]
        if transport then
            local available, availability_reason = transport:is_available()
            
            if available then
                local success, send_result = transport:send(content)
                results[transport_name] = {
                    success = success,
                    message = send_result,
                    priority = transport:get_priority()
                }
                
                if success then
                    success_count = success_count + 1
                    if not primary_success then
                        primary_success = true
                    end
                end
            else
                results[transport_name] = {
                    success = false,
                    message = availability_reason,
                    skipped = true
                }
            end
        end
    end
    
    -- 回報結果
    if primary_success then
        return true, results
    else
        return false, results
    end
end

-- 註冊自定義傳輸方式
function M.register_transport(name, transport)
    -- 驗證傳輸介面
    local required_methods = {"is_available", "send", "get_priority", "get_name"}
    for _, method in ipairs(required_methods) do
        if type(transport[method]) ~= "function" then
            error(string.format("Transport must implement %s method", method))
        end
    end
    
    transports[name] = transport
    return true
end

-- 移除傳輸方式
function M.unregister_transport(name)
    if transports[name] then
        transports[name] = nil
        return true
    end
    return false
end

-- 獲取可用傳輸方式
function M.get_available_transports()
    local available = {}
    
    for name, transport in pairs(transports) do
        local is_available, reason = transport:is_available()
        available[name] = {
            name = transport:get_name(),
            priority = transport:get_priority(),
            available = is_available,
            reason = reason
        }
    end
    
    return available
end

-- 測試所有傳輸方式
function M.test_all_transports()
    local test_content = "Clipboard transport test - " .. os.date("%Y-%m-%d %H:%M:%S")
    local results = {}
    
    for name, transport in pairs(transports) do
        local available, availability_reason = transport:is_available()
        
        if available then
            local success, send_result = transport:send(test_content)
            results[name] = {
                available = true,
                test_success = success,
                message = send_result
            }
        else
            results[name] = {
                available = false,
                message = availability_reason
            }
        end
    end
    
    return results
end

-- 設定傳輸優先級
function M.set_transport_priority(priority_list)
    local config = require('utils.clipboard.config')
    return config.update({transport_priority = priority_list})
end

-- 獲取傳輸統計
function M.get_transport_stats()
    local stats = {}
    
    for name, transport in pairs(transports) do
        stats[name] = {
            name = transport:get_name(),
            priority = transport:get_priority(),
            registered = true
        }
    end
    
    return stats
end

-- 診斷傳輸狀態
function M.diagnose()
    local diagnosis = {
        available_transports = M.get_available_transports(),
        test_results = M.test_all_transports(),
        current_priority = require('utils.clipboard.config').get('transport_priority')
    }
    
    return diagnosis
end

return M