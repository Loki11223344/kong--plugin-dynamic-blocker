-- handler.lua
local CustomHandler = {
    VERSION = "1.1.0",
    PRIORITY = 1000, 
  }

  local jwt_auth = require "kong.plugins.pomodoro-plugin.access.jwt_auth"
  local pomodoro = require "kong.plugins.pomodoro-plugin.access.pomodoro"
  local redis_shield = require "kong.plugins.pomodoro-plugin.access.redis_shield"
  
  function CustomHandler:access(conf)
    
  
    -- 1. 首先执行身份解析（无副作用，解析并组装 Header）
    jwt_auth.execute(conf)
  
    -- 2. 其次执行番茄钟限流（有拦截权，可能中断请求）
    pomodoro.execute(conf)
  
    -- 3. （预留位）未来这里可以无缝接入 Redis 黑名单防护模块...
    redis_shield.execute(conf)
  
  end
  
  return CustomHandler