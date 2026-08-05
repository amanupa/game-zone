# Game Zone Backend - PostgreSQL Database & Schema Standards

## 1. Database Architecture & Scale Parameters (10M Users)
- **Primary Database**: PostgreSQL 15+.
- **Connection Management**: Connection pooling via `pg-pool` or PgBouncer. Max connections tuned to database instance memory (e.g., 20 connections per node instance, statement_timeout = 5000ms).
- **Read/Write Segregation**: All mutation queries (`INSERT`, `UPDATE`, `DELETE`) hit the Primary DB; high-throughput read queries hit Read Replicas.

---

## 2. Table Design & Column Standards

### Primary Keys
- Use **`UUIDv4`** or **`TSID`** (Time-Sorted Unique Identifier) for all primary keys.
- **Rule**: Never use auto-incrementing sequential integers (`SERIAL` / `BIGSERIAL`) for public-facing entities to prevent enumeration attacks and ID prediction.

### Audit Columns Standard
Every single relational table MUST include the following audit fields:
```sql
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
deleted_at TIMESTAMPTZ DEFAULT NULL -- Soft delete tracking
```

### Financial Data Type Standard
- Financial values (Wallet balances, Transaction amounts, Entry fees) MUST be stored as:
  - `NUMERIC(18, 4)` OR `BIGINT` (amount in smallest currency unit / cents / sats).
- **STRICT PROHIBITION**: NEVER use `FLOAT`, `DOUBLE PRECISION`, or `REAL` for financial data due to floating-point rounding errors.

---

## 3. Indexing Strategy for 10M Users scale

### 1. B-Tree Indexes
- Mandatory on all Foreign Keys (`user_id`, `game_id`, `room_id`).
- Mandatory on unique lookup fields (`email`, `username`, `phone_number`).

### 2. Compound Indexes & Leftmost Prefix Rule
- When querying by multiple columns (e.g. finding user registrations in an event by status):
```sql
CREATE INDEX idx_registrations_event_status ON registrations (event_id, status, created_at DESC);
```

### 3. Partial Indexes for Soft Deletes
```sql
CREATE INDEX idx_users_active_email ON users (email) WHERE deleted_at IS NULL;
```

### 4. Mandatory Query Plan Verification
Before submitting any migration, the AI Agent MUST run `EXPLAIN ANALYZE` on all proposed queries to verify:
- Index Scan / Index Only Scan is used (NO Sequential Scans on tables over 10,000 rows).
- Execution cost is within acceptable SLA.

---

## 4. Declarative Range Partitioning
For high-volume transaction/event tables expected to exceed 10 million rows (e.g., `wallet_transactions`, `game_match_logs`, `audit_logs`):
```sql
CREATE TABLE wallet_transactions (
    id UUID NOT NULL,
    wallet_id UUID NOT NULL,
    amount NUMERIC(18, 4) NOT NULL,
    type VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Partition creation by month
CREATE TABLE wallet_transactions_2026_07 PARTITION OF wallet_transactions
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');
```
