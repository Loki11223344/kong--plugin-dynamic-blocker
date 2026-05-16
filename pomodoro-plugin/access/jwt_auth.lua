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
        local payload = cjson.decode(payload_json)
        
        if payload.userId then
          -- 注入 Header，完成透传
          kong.service.request.set_header("X-User-Id", tostring(payload.userId))
          kong.log.notice("✅ [JWT模块] 解析成功，透传 X-User-Id: ", payload.userId)
          kong.service.request.clear_header("Authorization")
        end
      end
    end
  end
  
  -- 如果需要强制鉴权，可以在这里直接 return kong.response.exit(401, ...)
  -- 我们这里先让它作为非强制模块静默运行
end

return _M