# Game Zone Horizontal Scaling & Replication Architecture

This document details the database partition architecture, physical replication topology, read replica query routing, and Citus sharding roadmap for handling **10 Million+ Users**.

---

## 1. Table Partitioning Strategy

High-volume telemetry, logging, and financial tables use **Declarative Range Partitioning** by `created_at` (monthly partitions).

```sql
-- Wallet Transactions Parent Table
CREATE TABLE wallet_transactions (
    id UUID DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL,
    reference_id UUID NOT NULL,
    transaction_type transaction_type_enum NOT NULL,
    account_type ledger_account_type_enum NOT NULL,
    amount NUMERIC(15,2) NOT NULL CHECK (amount > 0.00),
    balance_after NUMERIC(15,2) NOT NULL CHECK (balance_after >= 0.00),
    description TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Monthly Partitions Example
CREATE TABLE wallet_transactions_y2026m07 PARTITION OF wallet_transactions
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');

CREATE TABLE wallet_transactions_y2026m08 PARTITION OF wallet_transactions
    FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');
```

**Partitioned Tables**: `wallet_transactions`, `outbox_events`, `notification_logs`, `audit_logs`.

---

## 2. Replication Topology & Read Replicas

```
                     +---------------------------+
                     |  PostgreSQL Primary Node  |
                     |     (Writes / Mutations)  |
                     +---------------------------+
                                   |
                +------------------+------------------+
                | Physical Streaming Replication (WAL) |
                v                                     v
   +-------------------------+           +-------------------------+
   |  Read Replica Node 1    |           |  Read Replica Node 2    |
   |  (Leaderboard / Views)  |           |  (Tournament Search)    |
   +-------------------------+           +-------------------------+
```

1. **Primary Cluster**: Handles all `INSERT`, `UPDATE`, `DELETE` transactions and atomic PL/pgSQL procedures.
2. **Read Replica Array**: 3+ streaming read replicas offloading read-heavy endpoints (`GET /tournaments`, `GET /leaderboard`, `GET /users/profile`).
3. **Replication Lag Monitoring**: Alerts trigger if physical WAL replication lag exceeds 50ms (`pg_stat_replication`).

---

## 3. Sharding & Future Scaling Roadmap (50M+ Users)

When single-node memory and partition limits are exceeded:
- **Citus Extension Integration**: Shard `users`, `wallets`, and `event_registrations` by `user_id` hash.
- **Microservice Database Decoupling**: Isolate `wallets` and `payments` into a dedicated financial database instance, keeping domain event synchronization strictly asynchronous via Kafka.
