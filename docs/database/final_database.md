# Game Zone Master Consolidated Database Architecture Specification

## Executive Overview

The Game Zone Platform PostgreSQL Database Architecture is a production-grade relational database designed for high-concurrency esports tournament management. Engineered to scale seamlessly to **10 Million Registered Users**, **500,000 Concurrent Active Users (CCU)**, and **10,000+ Requests Per Second (RPS)**, the database provides extreme performance, ACID transactional safety, zero financial drift, and event delivery guarantees.

---

## Technical Highlights & Standards

- **Engine**: PostgreSQL 16+
- **Primary Keys**: 128-bit UUID v4 generated via `gen_random_uuid()`
- **Normalization**: Strictly 3rd Normal Form (3NF)
- **Financial Architecture**: Double-Entry Bookkeeping Ledger
- **Async Messaging**: Transactional Outbox Pattern for Apache Kafka
- **Partitioning**: Declarative Range Partitioning by `created_at` (monthly)
- **Concurrency Control**: Row-level locking (`SELECT ... FOR UPDATE SKIP LOCKED`)
- **Connection Pooling**: PgBouncer Transaction Pooling Mode
- **Security**: Row Level Security (RLS), RBAC, column encryption (AES-256 / SHA-256)

---

## Complete Table Catalog (33 Tables)

1. `users` - Core user profile records
2. `user_auth` - Local credentials & OAuth subject IDs
3. `roles` - RBAC role definitions
4. `permissions` - Granular permission keys
5. `user_roles` - User to role assignments
6. `role_permissions` - Role to permission mappings
7. `user_game_identities` - Player handles & UIDs per game (BGMI, Free Fire, COD)
8. `kyc_verifications` - Government ID compliance records
9. `games` - Supported game catalog
10. `game_modes` - Game lobby sizes and modes
11. `events` - Tournament metadata and state machine
12. `event_prize_structures` - Rank-based prize pool distributions
13. `teams` - Player esports teams
14. `team_members` - Team roster assignments
15. `event_registrations` - Player & squad slot registrations
16. `match_rooms` - Lobby room credentials (Room ID, Password)
17. `room_allocations` - Seating assignments in game lobbies
18. `wallets` - User monetary account balances
19. `wallet_locks` - Escrow locks for tournament entries
20. `wallet_transactions` - Partitioned double-entry financial ledger
21. `payment_transactions` - Payment gateway order processing log
22. `payouts` - Player withdrawals and TDS tax deductions
23. `match_results` - Match result score header
24. `result_submissions` - Player score submissions & screenshot proof
25. `result_disputes` - Score dispute claims & admin arbitration
26. `player_game_stats` - Aggregated player career statistics
27. `event_leaderboards` - Tournament rank standings and winnings
28. `outbox_events` - Partitioned transactional outbox for Kafka
29. `notification_templates` - Multi-channel message body format strings
30. `notification_logs` - Partitioned outbound notification log
31. `scheduled_tasks` - System cron execution tracking
32. `audit_logs` - Partitioned immutable security audit trail
33. `system_configurations` - Dynamic platform feature toggles

---

## Architectural Documentation Map

All specifications are modularized under `docs/database/`:

- [database_requirements.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/database_requirements.md) - System scale goals & 3NF rules
- [database_design.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/database_design.md) - Architectural design patterns & schema taxonomy
- [er_diagram.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/er_diagram.md) - Mermaid entity-relationship diagram
- [tables.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/tables.md) - Field-by-field table dictionary
- [relationships.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/relationships.md) - Foreign Key matrix & DAG dependency proof
- [constraints.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/constraints.md) - PK, FK, UNIQUE, and CHECK constraints
- [indexes.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/indexes.md) - Composite, Partial & GIN indexing strategies
- [triggers.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/triggers.md) - Automated update & outbox triggers
- [functions.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/functions.md) - PL/pgSQL stored procedures for atomic workflows
- [views.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/views.md) - Operational and analytical views
- [migrations.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/migrations.md) - Sequential deployment guide
- [rollback.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/rollback.md) - Emergency rollback scripts
- [seed_data.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/seed_data.md) - Seed data specification
- [performance.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/performance.md) - PostgreSQL configuration & tuning
- [security.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/security.md) - RLS, RBAC, Encryption & Audit logs
- [scaling.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/scaling.md) - Partitioning & Read Replica topology
- [review.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/review.md) - Architectural audit checklist
- [diff.md](file:///Users/amanupadhyay/development/game%20Zone%20Backend/docs/database/diff.md) - Iteration validation diff log (`NO DIFFERENCE FOUND`)
