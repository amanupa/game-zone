# Game Zone Data Integrity Constraints Specification

This document details all Primary Key, Unique, Foreign Key, and Check Constraints configured to enforce business rules at the database level.

---

## 1. Domain Check Constraints

### 1.1 `users` Table
- `chk_users_email_format`: `email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'`
- `chk_users_phone_format`: `phone IS NULL OR phone ~* '^\+?[1-9]\d{1,14}$'`

### 1.2 `events` Table
- `chk_events_entry_fee_positive`: `entry_fee >= 0.00`
- `chk_events_prize_pool_positive`: `prize_pool >= 0.00`
- `chk_events_slots_sanity`: `max_slots > 0 AND filled_slots >= 0 AND filled_slots <= max_slots`
- `chk_events_schedule_order`: `registration_end_at > registration_start_at AND tournament_start_at >= registration_end_at AND (tournament_end_at IS NULL OR tournament_end_at > tournament_start_at)`

### 1.3 `event_prize_structures` Table
- `chk_prize_rank_range`: `rank_min > 0 AND rank_max >= rank_min`
- `chk_prize_amount_positive`: `prize_amount >= 0.00`
- `chk_prize_percentage`: `percentage_share IS NULL OR (percentage_share >= 0.00 AND percentage_share <= 100.00)`

### 1.4 `wallets` Table
- `chk_wallets_available_balance_positive`: `available_balance >= 0.00`
- `chk_wallets_locked_balance_positive`: `locked_balance >= 0.00`
- `chk_wallets_totals_positive`: `total_deposited >= 0.00 AND total_withdrawn >= 0.00 AND total_won >= 0.00`

### 1.5 `wallet_locks` Table
- `chk_wallet_locks_amount_positive`: `amount > 0.00`

### 1.6 `wallet_transactions` Table
- `chk_wallet_transactions_amount_positive`: `amount > 0.00`
- `chk_wallet_transactions_balance_after`: `balance_after >= 0.00`

### 1.7 `payment_transactions` Table
- `chk_payments_amount_positive`: `amount > 0.00`
- `chk_payments_fee_positive`: `fee_amount >= 0.00 AND tax_amount >= 0.00`

### 1.8 `payouts` Table
- `chk_payouts_amount_positive`: `amount > 0.00`
- `chk_payouts_tax_positive`: `tax_deducted_tds >= 0.00`
- `chk_payouts_net_calculation`: `net_amount = (amount - tax_deducted_tds)`

### 1.9 `result_submissions` Table
- `chk_submissions_rank_positive`: `rank_achieved > 0`
- `chk_submissions_kills_positive`: `kills_count >= 0`
- `chk_submissions_score_positive`: `score_points >= 0.00`

### 1.10 `player_game_stats` Table
- `chk_stats_counters_positive`: `total_matches >= 0 AND wins >= 0 AND kills >= 0 AND deaths >= 0 AND assists >= 0 AND total_earnings >= 0.00`
- `chk_stats_win_rate_range`: `win_rate >= 0.00 AND win_rate <= 100.00`

---

## 2. Unique Constraints Matrix

| Table | Constraint Name | Columns | Business Rule Enforced |
| :--- | :--- | :--- | :--- |
| `users` | `uq_users_username` | `username` | Duplicate usernames prohibited |
| `users` | `uq_users_email` | `email` | Duplicate emails prohibited |
| `users` | `uq_users_phone` | `phone` | Duplicate phone numbers prohibited |
| `roles` | `uq_roles_name` | `name` | Duplicate role names prohibited |
| `permissions` | `uq_permissions_name` | `name` | Duplicate permission keys prohibited |
| `user_game_identities` | `uq_user_game_identity` | `(game_id, in_game_id)` | One player handle per game UID |
| `user_game_identities` | `uq_user_game_user` | `(user_id, game_id)` | One handle per user per game |
| `games` | `uq_games_code` | `code` | Unique game identifier code |
| `game_modes` | `uq_game_modes_name` | `(game_id, name)` | Unique mode name per game |
| `events` | `uq_events_slug` | `slug` | Unique SEO slug |
| `teams` | `uq_teams_tag` | `tag` | Unique team tag |
| `event_registrations` | `uq_event_user_reg` | `(event_id, user_id)` | One registration per user per tournament |
| `event_registrations` | `uq_event_slot` | `(event_id, slot_number)` | Unique slot assignment per tournament |
| `wallets` | `uq_wallets_user` | `user_id` | One wallet per user |
| `match_results` | `uq_match_results_room` | `room_id` | One result header per match room |
| `notification_templates` | `uq_notification_templates_code` | `code` | Unique template code |
| `system_configurations` | `uq_system_config_key` | `config_key` | Unique key for feature config |

---

## 3. Composite Primary Key Matrix

| Table | Primary Key Columns | Purpose |
| :--- | :--- | :--- |
| `user_roles` | `(user_id, role_id)` | Junction mapping table |
| `role_permissions` | `(role_id, permission_id)` | Junction mapping table |
| `team_members` | `(team_id, user_id)` | Team membership mapping |
