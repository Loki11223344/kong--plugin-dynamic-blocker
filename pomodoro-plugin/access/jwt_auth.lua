-- access/jwt_auth.lua
local cjson = require "cjson"

local _M = {} -- 定义当前模块

-- 私有基础函数：Base64解码
local function decode_base64url(str)
  local b64 = str:gsub('-', '+'):gsub('_', '/')
  local pad = #b64 % 4
  if pad > 0 then
    b64 = b64 .. string.rep('=', 4 - pad)
  end
  return ngx.decode_base64(b64)
end

-- 暴露给外部的核心执行函数
function _M.execute(conf)
  local auth_header = kong.request.get_header("Authorization")
  
  if auth_header and auth_header:find("Bearer ") == 1 then
    local token = auth_header:sub(8)
    local _, _, payload_b64 = token:find("^[^%.]+%.([^%.]+)%.")
    
    if payload_b64 then
      local payload_json = decode_base64url(payload_b64)
      if payload_json then
        -- 💡 高级技巧：使用 pcall 防止恶意伪造的 JSON 导致网关崩溃
        local status, payload = pcall(cjson.decode, payload_json)
        
        if status and payload and payload.userId then
          -- 注入 Header，完成透传
          kong.service.request.set_header("X-User-Id", tostring(payload.userId))
          kong.log.notice("✅ [JWT模块] 解析成功，透传 X-User-Id: ", payload.userId)
          
          -- 为了安全，网关层消费掉 Token，不透传给后端，避免后端误用
          kong.service.request.clear_header("Authorization")
          
          -- 🚀 核心修复 1：成功了就立刻 return，放行请求！
          return
        end
      end
    end
  end
  
  -- 🚀 核心修复 2：只有上面所有条件都没命中（没带token、token格式错、没解析出userId），才会走到这里
  -- 并且删除了不存在的 rule 变量
  return kong.response.exit(401, {
    error = "Unauthorized",
    message = "Missing or invalid JWT token.",
    status = "BLOCKED"
  })
end

return _M