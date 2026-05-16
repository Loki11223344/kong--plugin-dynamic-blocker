-- access/pomodoro.lua
local _M = {}

function _M.execute(conf)
  -- 如果没开启开关，直接跳出本模块
  if not conf.enable_dynamic_clock then
    return
  end

  local current_time = os.date("*t")
  local current_minute = current_time.min
  local current_cycle_min = current_minute % 30

  if current_cycle_min < 25 then
    local remain_minutes = 25 - current_cycle_min
    kong.log.notice("🔴 [番茄钟模块] 处于专注时段，流量拦截！")

    -- 触发拦截！
    return kong.response.exit(403, {
      status = "BLOCKED",
      error = "POMODORO_FOCUS_MODE_ACTIVE",
      message = conf.message,
      remain_focus_minutes = remain_minutes
    }, {
      ["Content-Type"] = "application/json; charset=utf-8"
    })
  end

  kong.log.notice("🟢 [番茄钟模块] 处于休息时段，放行！")
end

return _M