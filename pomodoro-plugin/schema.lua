return {
    name = "pomodoro-plugin",
    fields = {
      { config = {
          type = "record",
          fields = {
            -- 自定义拦截提示语
            { message = { type = "string", default = "🍅 专注时间到！去背 N1 语法吧！" } },
            -- 自动番茄钟拦截开关（默认开启）
            { enable_dynamic_clock = { type = "boolean", default = true } },
            { redis_host = { type = "string", default = "redis" } }, -- docker里的网络别名
            { redis_port = { type = "number", default = 6379 } },
          },
      }, },
    },
  }