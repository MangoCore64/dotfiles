-- 剪貼板模組重定向
-- 此文件保持向後兼容性，實際功能已遷移至模組化架構

-- 🔧 Phase 3 模組化重構完成
-- 原本 1010 行的巨型文件已拆分為以下專責模組：
-- - clipboard/init.lua     : 主入口和公共API (~180行)
-- - clipboard/config.lua   : 配置管理 (~180行)
-- - clipboard/security.lua : 安全檢測 (~350行)
-- - clipboard/state.lua    : 狀態管理 (~320行)
-- - clipboard/core.lua     : 核心邏輯 (~250行)
-- - clipboard/transport.lua: 傳輸管理 (~280行)
-- - clipboard/utils.lua    : 工具函數 (~240行)

-- 直接導出模組化實現
return require('utils.clipboard.init')