# Game Zone Architecture & Database Design Specification

## 1. Architectural Architecture & Principles

The Game Zone database is designed to act as a resilient, highly scalable relational backing store. To support **10 Million Registered Users** and high-frequency real-time esports interactions, the architecture incorporates the following core design patterns:

### 1.1 3rd Normal Form (3NF) Compliance & Zero Redundancy
Every non-key attribute is dependent strictly on the key, the whole key, and nothing but the key. Derived metrics (such as `win_rate` or `kd_ratio`) are computed dynamically or updated asynchronously via triggers to avoid write contention on transactional tables.

### 1.2 Double-Entry Bookkeeping Ledger
Financial accounting uses an immutable double-entry ledger design. Money is never updated directly in place without a balancing debit and credit entry in `wallet_transactions`.

```
[ User Deposit ]        --> Debit: GATEWAY_SETTLEMENT  | Credit: USER_WALLET
[ Tournament Entry ]    --> Debit: USER_WALLET          | Credit: SYSTEM_ESCROW
[ Prize Payout ]        --> Debit: SYSTEM_ESCROW        | Credit: USER_WALLET (Winner)
[ Platform Commission ] --> Debit: SYSTEM_ESCROW        | Credit: PLATFORM_FEE
```

### 1.3 Transactional Outbox Pattern for Asynchronous Event Bus (Kafka)
To guarantee consistency between database updates and Kafka event publishing (e.g. `gamezone.events.registration.opened`, `gamezone.payments.deposit.completed`), state mutations write an event record into `outbox_events` within the same ACID transaction. An external CDC / outbox poller forwards these events to Kafka seamlessly.

```
+-------------------------------------------------------------------+
|                     POSTGRESQL ACID TRANSACTION                    |
|                                                                   |
| 1. UPDATE events SET filled_slots = filled_slots + 1              |
| 2. INSERT INTO event_registrations (...)                          |
| 3. INSERT INTO wallet_transactions (...)                          |
| 4. INSERT INTO outbox_events (aggregate_type, event_type, ...)    |
+-------------------------------------------------------------------+
                                  |
                                  v
                       [ Outbox Poller Worker ]
                                  |
                                  v
                        [ Apache Kafka Topic ]
```

---

## 2. Schema Taxonomy & Domain Modules

The database structure is organized across 10 functional domain schemas/modules:

1. **Authentication & Identity (`auth`, `users`)**: User identity, credentials, OAuth connections, dynamic RBAC permission matrices, KYC compliance records.
2. **Game Catalog & Modes (`games`)**: Supported games (BGMI, Free Fire, COD), game modes (Solo/Duo/Squad), player seating configurations.
3. **Tournaments & Events (`events`)**: Tournament lifecycle, schedules, rule sets, multi-tier prize pool allocations.
4. **Teams & Registrations (`registrations`)**: Team rosters, tournament entry registrations, slot reservations, waitlists.
5. **Match Rooms & Distribution (`rooms`)**: Lobby credentials (Room ID, Password), seat allocations, credential notification dispatch.
6. **Financial Ledger & Payments (`wallets`, `payments`)**: User balances, locked escrow funds, double-entry transaction log, payment gateway webhooks, TDS tax payouts.
7. **Match Results & Disputes (`results`)**: Player score submissions, proof screenshots, automated cross-validation, admin dispute workflows.
8. **Player Telemetry & Leaderboards (`leaderboard`)**: Aggregate player statistics, K/D ratios, tournament rankings.
9. **Outbox & Notifications (`notifications`)**: Kafka transactional outbox, multi-channel templates (In-App, Push, Email, SMS), delivery logs.
10. **System Operations & Audit (`system`)**: Cron scheduler triggers, system configuration key-values, partitioned immutable audit logs.

---

## 3. High-Concurrency & Locking Strategies

### 3.1 Pessimistic Row Locking for Registration & Wallet Locks
During high-traffic tournament drop events, concurrent registration requests lock specific rows using `SELECT ... FOR UPDATE` or atomic condition updates to prevent overselling.

```sql
-- Atomic slot reservation check
UPDATE events 
SET filled_slots = filled_slots + 1 
WHERE id = p_event_id AND filled_slots < max_slots AND status = 'REGISTRATION_OPEN';
```

### 3.2 Partitioning Strategy
Append-heavy tables (`wallet_transactions`, `audit_logs`, `notification_logs`, `outbox_events`) utilize **Declarative Range Partitioning** by `created_at` grouped into monthly partitions. This prevents table bloat, keeps B-tree indexes compact, and allows instant archival via table truncation/detachment.

---

## 4. Primary Key & Audit Conventions

- **Primary Keys**: Every table uses a 128-bit `UUID v4` primary key (`id UUID PRIMARY KEY DEFAULT gen_random_uuid()`).
- **Timestamp Precision**: All timestamps are stored using `TIMESTAMP WITH TIME ZONE` (`TIMESTAMPTZ`) to ensure global timezone consistency.
- **Audit Columns**:
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`
  - `updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`
  - `deleted_at TIMESTAMPTZ NULL` (Soft delete indicator)
  - `created_by UUID NULL REFERENCES users(id)`
  - `updated_by UUID NULL REFERENCES users(id)`
