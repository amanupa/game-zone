# Game Zone Migration Execution Guide

This document outlines the sequential execution protocol for deploying database migrations safely in production.

---

## 1. Migration Execution Pipeline

Migrations must be run in strict numeric order using a migration tool (such as Flyway, Liquibase, or custom runner) with transaction wrapping (`BEGIN ... COMMIT`).

| Order | Migration File | Description | Rollback Target |
| :--- | :--- | :--- | :--- |
| **001** | `001_extensions_and_enums.sql` | Enable `pgcrypto` and create PostgreSQL ENUM types | Drop enums & extension |
| **002** | `002_users_and_auth.sql` | Core identity tables (`users`, `user_auth`, RBAC, KYC) | Drop identity tables |
| **003** | `003_games_and_events.sql` | Catalog & tournament state machine (`games`, `events`) | Drop catalog tables |
| **004** | `004_teams_and_registrations.sql` | Rosters & registration slots (`teams`, `registrations`) | Drop registration tables |
| **005** | `005_rooms_and_lobbies.sql` | Room credentials & seating allocations (`match_rooms`) | Drop room tables |
| **006** | `006_wallets_and_payments.sql` | Double-entry ledger & payments (`wallets`, `transactions`) | Drop ledger tables |
| **007** | `007_results_and_disputes.sql` | Results, proof submissions & anti-cheat disputes | Drop result tables |
| **008** | `008_leaderboards_and_stats.sql` | Career statistics & tournament leaderboards | Drop leaderboard tables |
| **009** | `009_notifications_and_outbox.sql` | Partitioned outbox & multi-channel logs | Drop outbox tables |
| **010** | `010_scheduler_and_audit.sql` | Cron task execution & partitioned audit logs | Drop audit tables |
| **011** | `011_triggers_and_functions.sql` | PL/pgSQL procedures & validation triggers | Drop stored procedures |
| **012** | `012_views.sql` | Analytical & operational views | Drop views |

---

## 2. CI/CD Integration & Zero-Downtime Deployment
1. **Pre-flight Checks**: Execute dry-run parsing on staging database.
2. **Locking Safeguards**: Set `lock_timeout = '5s'` to prevent migration locks from blocking live production queries.
3. **Additive Schema Updates**: Database columns are added as `NULLABLE` first, backfilled asynchronously, and converted to `NOT NULL` in secondary migrations.
