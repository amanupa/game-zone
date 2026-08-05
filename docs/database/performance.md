# Game Zone High-Concurrency Database Performance Specification

This document details database engine tuning, connection pooling, memory configuration, and autovacuum optimization to support **10 Million Users** and **10,000+ RPS**.

---

## 1. Connection Pooling & Infrastructure Topology

At 500,000 CCU, opening direct connections per request will exhaust PostgreSQL process limits (`max_connections`). Connection pooling is enforced via **PgBouncer** running in Transaction Pooling mode.

```
[ 10,000+ Application Worker Pods ]
               |
               v
  [ PgBouncer Layer (Transaction Mode) ]  <-- Max 10,000 incoming client connections
               |
               v (Pooled connections: max 200)
   [ PostgreSQL Primary Cluster ]
```

---

## 2. PostgreSQL Server Parameter Configuration (`postgresql.conf`)

Tuned for a dedicated 64 vCPU / 256 GB RAM Primary Database Node:

| Parameter | Recommended Value | Rationale |
| :--- | :--- | :--- |
| `max_connections` | `300` | Capped low to prevent RAM context switching; managed by PgBouncer |
| `shared_buffers` | `64GB` | 255% of total server RAM allocated to Postgres buffer cache |
| `effective_cache_size` | `192GB` | Total OS + Postgres cache available for query planning |
| `work_mem` | `64MB` | Memory for in-memory sorts/joins per query operation |
| `maintenance_work_mem` | `4GB` | Memory allocated for VACUUM, CREATE INDEX, and DDL |
| `wal_buffers` | `64MB` | Memory for unwritten WAL data |
| `min_wal_size` | `10GB` | Reduces WAL checkpoint frequency during flash registrations |
| `max_wal_size` | `40GB` | Accommodates heavy burst write volumes |
| `checkpoint_completion_target` | `0.9` | Spreads WAL writes smoothly over checkpoint interval |
| `random_page_cost` | `1.1` | Optimized for high-speed NVMe SSD storage |
| `effective_io_concurrency` | `200` | Enables parallel SSD I/O reads |

---

## 3. Autovacuum Tuning for High-Volume Partitioned Tables

Heavy insert/update activity on `wallet_transactions`, `outbox_events`, and `events` produces dead tuples. Aggressive autovacuum parameters prevent table bloat:

```ini
autovacuum = on
autovacuum_max_workers = 8
autovacuum_naptime = 15s
autovacuum_vacuum_scale_factor = 0.05
autovacuum_analyze_scale_factor = 0.02
autovacuum_vacuum_cost_limit = 2000
```

---

## 4. Query Tuning Benchmark SLA Targets

| Query Path | Max Latency SLA | Target Access Method |
| :--- | :--- | :--- |
| User Auth Lookup | `< 2ms` | Index Scan on `idx_users_email` |
| Registration Slot Reserve | `< 5ms` | Atomic UPDATE on PK with Row Lock |
| Wallet Balance Fetch | `< 1ms` | Index Only Scan on `idx_wallets_user` |
| Outbox Event Poll | `< 3ms` | Partial Index Scan with `SKIP LOCKED` |
| Leaderboard Aggregation | `< 10ms` | Index Scan on `idx_event_leaderboards_rank` |
