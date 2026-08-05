# Game Zone Backend - Performance & Scalability (10 Million Users)

## 1. SLA Targets & Scale Benchmarks
- **Total Registered Users**: 10 Million Users.
- **Peak Concurrent Active Users (CCU)**: 500,000 Users.
- **Peak Throughput**: 10,000+ Requests Per Second (RPS).
- **Read API Latency SLA**: p95 < 50ms, p99 < 100ms.
- **Write API Latency SLA**: p95 < 100ms, p99 < 200ms.
- **Real-Time Room / Leaderboard Latency SLA**: p99 < 30ms.

---

## 2. Multi-Level Caching Topology

```
[ Express API Node ] ---> [ L1: Node In-Memory LRU Cache (Fastest, TTL: 5s) ]
                                | (Cache Miss)
                                v
                          [ L2: Redis Cluster (TTL: 1h, Invalidate on Write) ]
                                | (Cache Miss)
                                v
                          [ PostgreSQL Read Replica Database ]
```

### Caching Rules:
1. **Cache-Aside Pattern**: Always attempt to read from Redis; on cache miss, query PostgreSQL Read Replica, populate Redis with TTL, and return.
2. **Cache Invalidation**: On write operations (e.g. profile update, score update), write to DB and publish cache invalidation signal.
3. **Cache Stampede Prevention**: Use distributed locking (Redlock algorithm) or probabilistic early expiration for ultra-hot keys (e.g., top leaderboard).

---

## 3. Scalable Cursor-Based Pagination (Seek Method)
- **STRICT PROHIBITION**: NEVER use `OFFSET / LIMIT` pagination on large tables (>10,000 rows), as offset scanning scales linearly $O(N)$ and degrades DB performance.
- **ALWAYS USE CURSOR-BASED PAGINATION** $O(1)$:

```sql
-- GOOD: Cursor seek query using (score, id) tuple
SELECT id, username, score, created_at
FROM leaderboards
WHERE (score, id) < ($last_score, $last_id)
ORDER BY score DESC, id DESC
LIMIT 20;
```

---

## 4. Node.js Event Loop Protection
- Never run CPU-heavy operations (e.g., cryptographic key generation, bulk JSON parsing > 10MB, intensive matrix calculations) on the main Express event loop thread.
- Offload intensive workloads to Worker Threads or background Kafka consumer background processes.
