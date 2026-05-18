# 🛡️ Kong Traffic Sentinel

A high-performance, enterprise-grade API Gateway traffic control and security plugin for Kong (OpenResty/Lua). 

This plugin is designed to decouple authentication from backend microservices and provide robust, nanosecond-level dynamic traffic interception under high concurrency scenarios.

## ✨ Core Features

- **JWT Authentication Decoupling:** Intercepts and validates JWTs at the gateway level, injecting `X-User-Id` headers into upstream requests to offload backend authentication pressure.
- **Double-Checked Locking (DCL) Protection:** Utilizes `lua-resty-lock` to implement a strict DCL mechanism during L1 cache invalidation, ensuring absolute singleton access to the Redis L2 cache and eliminating Cache Breakdown (缓存击穿) vulnerabilities under heavy traffic spikes.
- **L1/L2 Dynamic Caching Architecture:** Leverages `lua_shared_dict` (L1) and Redis (L2) for millisecond-level, zero-downtime hot updates of security rules.
- **JIT-Compiled Regex Engine:** Employs PCRE with `jo` flags (Compile-once & JIT) to keep dynamic firewall rules resident in memory, slashing regex matching latency to the nanosecond level.

## 🏗️ Architecture Flow
1. **Access Phase:** Intercept incoming HTTP requests.
2. **First Check (L1):** Query `lua_shared_dict` for cached blacklist rules.
3. **Lock & Double Check:** If L1 misses, acquire mutex lock -> check L1 again -> query Redis (L2) -> update L1 -> unlock.
4. **JIT Match:** Execute high-speed regex matching against the request path.
5. **Action:** Forward to upstream or instantly terminate with 403 Forbidden.

## 🚀 Quick Start
Start the entire gateway cluster (Kong + Postgres + Redis) using the provided Docker compose file:
```bash
docker compose up -d