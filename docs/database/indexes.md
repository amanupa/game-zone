# Game Zone Performance Indexing Strategy

This document outlines the indexing strategy designed to achieve sub-10ms response times for high-concurrency queries under **10 Million Users** and **10,000+ RPS**.

---

## 1. Indexing Strategy Overview

To maximize query throughput while minimizing write overhead:
1. **Primary Key B-Trees**: Automatically indexed by PostgreSQL.
2. **Foreign Key Indexes**: Created on every foreign key to prevent full table scans on JOINs and cascading deletes.
3. **Partial Indexes**: Built with `WHERE deleted_at IS NULL` or status filters to keep index tree depth small and cache-friendly.
4. **Composite Indexes**: Tailored for exact multi-column search paths (e.g. `(event_id, status)`).
5. **GIN Indexes**: Used on `JSONB` fields (`metadata_json`, `rules_json`) for fast document field queries.

---

## 2. Comprehensive Index Dictionary

### 2.1 Users & Authentication Module
- `idx_users_username`: B-Tree `(username)` WHERE `deleted_at IS NULL`
- `idx_users_email`: B-Tree `(email)` WHERE `deleted_at IS NULL`
- `idx_users_phone`: B-Tree `(phone)` WHERE `deleted_at IS NULL AND phone IS NOT NULL`
- `idx_users_kyc_status`: B-Tree `(kyc_status)` WHERE `deleted_at IS NULL`
- `idx_user_auth_user_id`: B-Tree `(user_id)`
- `idx_user_auth_provider`: B-Tree `(provider, provider_user_id)`
- `idx_user_game_identities_lookup`: B-Tree `(game_id, in_game_id)` WHERE `deleted_at IS NULL`
- `idx_user_game_identities_user`: B-Tree `(user_id, game_id)` WHERE `deleted_at IS NULL`

### 2.2 Tournaments & Events Module
- `idx_events_game_status`: Composite B-Tree `(game_id, status, registration_start_at)` WHERE `deleted_at IS NULL`
- `idx_events_status_schedule`: Composite B-Tree `(status, tournament_start_at)` WHERE `deleted_at IS NULL`
- `idx_events_slug`: B-Tree `(slug)` WHERE `deleted_at IS NULL`
- `idx_events_rules_gin`: GIN `(rules_json)`
- `idx_event_prize_structures_event`: B-Tree `(event_id, rank_min)`

### 2.3 Teams & Registrations Module
- `idx_teams_captain`: B-Tree `(captain_id)` WHERE `deleted_at IS NULL`
- `idx_teams_tag`: B-Tree `(tag)` WHERE `deleted_at IS NULL`
- `idx_event_registrations_event_user`: Composite `(event_id, user_id)` WHERE `deleted_at IS NULL`
- `idx_event_registrations_status`: Composite `(event_id, registration_status)` WHERE `deleted_at IS NULL`
- `idx_event_registrations_user`: B-Tree `(user_id)` WHERE `deleted_at IS NULL`

### 2.4 Match Rooms & Allocations Module
- `idx_match_rooms_event`: Composite `(event_id, status)`
- `idx_room_allocations_room`: Composite `(room_id, slot_number, seat_number)`
- `idx_room_allocations_user`: B-Tree `(user_id)`

### 2.5 Wallets & Payment Ledger Module
- `idx_wallets_user`: B-Tree `(user_id)` WHERE `deleted_at IS NULL`
- `idx_wallet_locks_active`: Composite `(wallet_id, event_id)` WHERE `is_released = FALSE`
- `idx_wallet_transactions_wallet_created`: Composite B-Tree `(wallet_id, created_at DESC)`
- `idx_wallet_transactions_reference`: B-Tree `(reference_id)`
- `idx_payment_transactions_user`: Composite `(user_id, created_at DESC)`
- `idx_payment_transactions_gateway_order`: B-Tree `(gateway, gateway_order_id)`
- `idx_payment_transactions_status`: B-Tree `(status)` WHERE `status = 'PENDING'`
- `idx_payouts_user_status`: Composite `(user_id, status)`

### 2.6 Results & Disputes Module
- `idx_match_results_event`: Composite `(event_id, room_id)`
- `idx_result_submissions_result`: Composite `(match_result_id, rank_achieved)`
- `idx_result_submissions_user`: B-Tree `(submitted_by)`
- `idx_result_disputes_status`: B-Tree `(status)` WHERE `status = 'OPEN'`

### 2.7 Telemetry & Leaderboards Module
- `idx_player_game_stats_game_rank`: Composite B-Tree `(game_id, total_earnings DESC, wins DESC)`
- `idx_event_leaderboards_rank`: Composite B-Tree `(event_id, rank ASC)`

### 2.8 Outbox & Operations Module
- `idx_outbox_events_pending`: Partial B-Tree `(created_at ASC)` WHERE `status = 'PENDING'`
- `idx_notification_logs_recipient`: Composite `(user_id, status)`
- `idx_audit_logs_actor`: Composite `(actor_id, created_at DESC)`
- `idx_audit_logs_resource`: Composite `(resource_type, resource_id)`

---

## 3. High-Frequency Query Execution Plan Targets

### Query 1: Active Tournament Listing
```sql
SELECT * FROM events 
WHERE game_id = $1 AND status = 'REGISTRATION_OPEN' 
ORDER BY registration_start_at ASC 
LIMIT 20;
```
- **Index Used**: `idx_events_game_status`
- **Execution Plan**: Index Scan (Cost < 0.05ms)

### Query 2: User Balance & Locked Escrow Check
```sql
SELECT available_balance, locked_balance 
FROM wallets 
WHERE user_id = $1 AND deleted_at IS NULL;
```
- **Index Used**: `idx_wallets_user`
- **Execution Plan**: Index Only Scan (Cost < 0.02ms)

### Query 3: Outbox Worker Event Polling
```sql
SELECT id, aggregate_type, aggregate_id, event_type, payload_json 
FROM outbox_events 
WHERE status = 'PENDING' 
ORDER BY created_at ASC 
LIMIT 100 
FOR UPDATE SKIP LOCKED;
```
- **Index Used**: `idx_outbox_events_pending`
- **Execution Plan**: Partial Index Scan with `SKIP LOCKED` (Zero lock contention)
