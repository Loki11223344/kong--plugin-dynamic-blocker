-- access/redis_shield.lua
local redis = require "resty.redis"
local cjson = require "cjson"
local resty_lock = require "resty.lock"
local _M = {}

function _M.execute(conf)
  -- 1. init cache
  local cache = ngx.shared.blacklist_cache
  if not cache then
    kong.log.err("fata error: cache can not access")
    return
  end

  -- 2. local cache get rules
  local rules_json = cache:get("regex_rules")

  -- 3. 如果本地没有缓存，需要去 Redis 拉取
  if not rules_json then
    -- add lock
    local lock, err = resty_lock:new("locks_cache")
    if not lock then return end

    local elapsed, err = lock:lock("update_redis_lock")

    if not elapsed then 
        kong.log.err("未能获取到锁: ", err)
        return 
    end
    rules_json = cache:get("regex_rules")

    if not rules_json then 
        kong.log.notice("拿到锁且 L1 确认无缓存，向 Redis 发起唯一请求！等待耗时:", elapsed, "ms")
        local red = redis:new()
        red:set_timeouts(1000, 1000, 1000)
        local ok = red:connect(conf.redis_host, conf.redis_port)
        if ok then
            local redis_rules = red:smembers("kong:blacklist:regex_rules")
            if redis_rules and type(redis_rules) == "table" and #redis_rules > 0 then
                rules_json = cjson.encode(redis_rules)
            else
                rules_json = "[]" -- 防穿透
            end
            cache:set("regex_rules", rules_json, 10)
            red:set_keepalive(10000, 10)
        end
    end
    lock:unlock()
  end

  -- 4. 执行匹配拦截阶段
  if rules_json then
    local rules = cjson.decode(rules_json)
    local current_path = kong.request.get_path()
    
    -- TODO: 遍历 rules 数组 (可使用 for _, rule in ipairs(rules) do)
    for _, rule in ipairs(rules) do
        local judge = ngx.re.match(current_path, rule, "jo")
        if judge then
            return kong.response.exit(403, {
                error = "Access Denied",
                message = "The request path is blocked by dynamic security rules.",
                hit_rule = rule
            })
        end

    end
  end
end

return _M