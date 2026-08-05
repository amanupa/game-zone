# Game Zone Relational Topology & Foreign Key Matrix

This document defines every foreign key relationship, cardinality, deletion behavior, update rule, and dependency topology to ensure zero circular dependencies.

---

## 1. Foreign Key Matrix

| Source Table | Source Column | Target Table | Target Column | Cardinality | ON DELETE | ON UPDATE | Rationale |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `user_auth` | `user_id` | `users` | `id` | 1:N | `CASCADE` | `CASCADE` | Authenticators die with user |
| `user_roles` | `user_id` | `users` | `id` | M:N | `CASCADE` | `CASCADE` | User role mapping cleanup |
| `user_roles` | `role_id` | `roles` | `id` | M:N | `CASCADE` | `CASCADE` | Role deletion revokes assignment |
| `role_permissions` | `role_id` | `roles` | `id` | M:N | `CASCADE` | `CASCADE` | Role permission cleanup |
| `role_permissions` | `permission_id` | `permissions` | `id` | M:N | `CASCADE` | `CASCADE` | Permission removal from roles |
| `user_game_identities` | `user_id` | `users` | `id` | 1:N | `CASCADE` | `CASCADE` | User game handles deleted with user |
| `user_game_identities` | `game_id` | `games` | `id` | N:1 | `RESTRICT` | `CASCADE` | Cannot delete game with active handles |
| `kyc_verifications` | `user_id` | `users` | `id` | 1:N | `CASCADE` | `CASCADE` | User KYC documents deleted with user |
| `kyc_verifications` | `verified_by` | `users` | `id` | N:1 | `SET NULL` | `CASCADE` | Verifier deletion preserves audit |
| `game_modes` | `game_id` | `games` | `id` | 1:N | `CASCADE` | `CASCADE` | Modes deleted with game |
| `events` | `game_id` | `games` | `id` | N:1 | `RESTRICT` | `CASCADE` | Protect games linked to events |
| `events` | `game_mode_id` | `game_modes` | `id` | N:1 | `RESTRICT` | `CASCADE` | Protect modes linked to events |
| `events` | `created_by` | `users` | `id` | N:1 | `SET NULL` | `CASCADE` | Preserve event if admin is deleted |
| `event_prize_structures` | `event_id` | `events` | `id` | 1:N | `CASCADE` | `CASCADE` | Payout structure deleted with event |
| `teams` | `captain_id` | `users` | `id` | 1:N | `RESTRICT` | `CASCADE` | Captain cannot be deleted without reassigning team |
| `team_members` | `team_id` | `teams` | `id` | M:N | `CASCADE` | `CASCADE` | Members removed if team deleted |
| `team_members` | `user_id` | `users` | `id` | M:N | `CASCADE` | `CASCADE` | Member record removed if user deleted |
| `event_registrations` | `event_id` | `events` | `id` | N:1 | `RESTRICT` | `CASCADE` | Events with active registrations protected |
| `event_registrations` | `user_id` | `users` | `id` | N:1 | `RESTRICT` | `CASCADE` | Users with registrations protected |
| `event_registrations` | `team_id` | `teams` | `id` | N:1 | `RESTRICT` | `CASCADE` | Registered teams protected |
| `event_registrations` | `payment_id` | `payment_transactions` | `id` | 1:1 | `SET NULL` | `CASCADE` | Reference to payment record |
| `match_rooms` | `event_id` | `events` | `id` | 1:N | `CASCADE` | `CASCADE` | Rooms deleted if event deleted |
| `room_allocations` | `room_id` | `match_rooms` | `id` | 1:N | `CASCADE` | `CASCADE` | Allocations deleted if room deleted |
| `room_allocations` | `user_id` | `users` | `id` | N:1 | `CASCADE` | `CASCADE` | Seat freed if user deleted |
| `room_allocations` | `team_id` | `teams` | `id` | N:1 | `SET NULL` | `CASCADE` | Team seat association |
| `wallets` | `user_id` | `users` | `id` | 1:1 | `RESTRICT` | `CASCADE` | Wallet cannot be deleted if user exists |
| `wallet_locks` | `wallet_id` | `wallets` | `id` | 1:N | `RESTRICT` | `CASCADE` | Active lock protects wallet |
| `wallet_locks` | `event_id` | `events` | `id` | N:1 | `RESTRICT` | `CASCADE` | Active lock protects event |
| `wallet_transactions` | `wallet_id` | `wallets` | `id` | 1:N | `RESTRICT` | `CASCADE` | Immutable financial ledger preservation |
| `payment_transactions` | `user_id` | `users` | `id` | N:1 | `RESTRICT` | `CASCADE` | Financial record retention |
| `payment_transactions` | `wallet_id` | `wallets` | `id` | N:1 | `RESTRICT` | `CASCADE` | Financial record retention |
| `payouts` | `user_id` | `users` | `id` | N:1 | `RESTRICT` | `CASCADE` | Withdrawal history retention |
| `payouts` | `wallet_id` | `wallets` | `id` | N:1 | `RESTRICT` | `CASCADE` | Withdrawal history retention |
| `match_results` | `event_id` | `events` | `id` | 1:N | `CASCADE` | `CASCADE` | Results deleted with event |
| `match_results` | `room_id` | `match_rooms` | `id` | 1:1 | `CASCADE` | `CASCADE` | Results deleted with room |
| `match_results` | `verified_by` | `users` | `id` | N:1 | `SET NULL` | `CASCADE` | Verifier user reference |
| `result_submissions` | `match_result_id` | `match_results` | `id` | 1:N | `CASCADE` | `CASCADE` | Submissions deleted with result header |
| `result_submissions` | `submitted_by` | `users` | `id` | N:1 | `RESTRICT` | `CASCADE` | User score submission retention |
| `result_submissions` | `team_id` | `teams` | `id` | N:1 | `SET NULL` | `CASCADE` | Team score reference |
| `result_disputes` | `match_result_id` | `match_results` | `id` | 1:N | `CASCADE` | `CASCADE` | Disputes deleted with match result |
| `result_disputes` | `raised_by` | `users` | `id` | N:1 | `RESTRICT` | `CASCADE` | Complainant reference retention |
| `result_disputes` | `against_user_id` | `users` | `id` | N:1 | `SET NULL` | `CASCADE` | Accused user reference |
| `result_disputes` | `resolved_by` | `users` | `id` | N:1 | `SET NULL` | `CASCADE` | Admin arbiter reference |
| `player_game_stats` | `user_id` | `users` | `id` | N:1 | `CASCADE` | `CASCADE` | Stats purged if user deleted |
| `player_game_stats` | `game_id` | `games` | `id` | N:1 | `CASCADE` | `CASCADE` | Stats purged if game deleted |
| `event_leaderboards` | `event_id` | `events` | `id` | 1:N | `CASCADE` | `CASCADE` | Leaderboard deleted with event |
| `event_leaderboards` | `user_id` | `users` | `id` | N:1 | `SET NULL` | `CASCADE` | User rank entry |
| `event_leaderboards` | `team_id` | `teams` | `id` | N:1 | `SET NULL` | `CASCADE` | Team rank entry |
| `notification_logs` | `user_id` | `users` | `id` | N:1 | `CASCADE` | `CASCADE` | Recipient user link |
| `notification_logs` | `template_id` | `notification_templates` | `id` | N:1 | `SET NULL` | `CASCADE` | Notification template link |
| `audit_logs` | `actor_id` | `users` | `id` | N:1 | `SET NULL` | `CASCADE` | Actor user link |
| `system_configurations` | `updated_by` | `users` | `id` | N:1 | `SET NULL` | `CASCADE` | Editor admin link |

---

## 2. Topological Sort Order & Direct Acyclic Graph (DAG) Proof

To prove there are zero circular dependencies, tables are initialized in exact topological order:

1. Level 0 (Zero Dependencies): `roles`, `permissions`, `games`, `notification_templates`, `scheduled_tasks`
2. Level 1: `users`, `game_modes`, `role_permissions`
3. Level 2: `user_auth`, `user_roles`, `user_game_identities`, `kyc_verifications`, `events`, `teams`, `wallets`, `system_configurations`
4. Level 3: `event_prize_structures`, `team_members`, `match_rooms`, `wallet_locks`, `payment_transactions`, `payouts`, `player_game_stats`, `audit_logs`, `notification_logs`
5. Level 4: `event_registrations`, `room_allocations`, `wallet_transactions`, `match_results`, `event_leaderboards`
6. Level 5: `result_submissions`, `result_disputes`
7. Auxiliary Partitioned Events: `outbox_events`

Because every dependency points strictly from a higher level to a lower level, **the database schema dependency graph is a Directed Acyclic Graph (DAG) with zero cycles.**
