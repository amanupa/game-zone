# Game Zone Emergency Rollback Specification

This document details reverse rollback commands for every deployed schema migration.

---

## 1. Sequential Emergency Rollback Commands

### Rollback Phase 1: Views & Stored Functions
```sql
DROP VIEW IF EXISTS v_global_player_rankings CASCADE;
DROP VIEW IF EXISTS v_disputed_matches_queue CASCADE;
DROP VIEW IF EXISTS v_user_wallet_summary CASCADE;
DROP VIEW IF EXISTS v_active_tournaments CASCADE;

DROP FUNCTION IF EXISTS fn_process_prize_payout(UUID);
DROP FUNCTION IF EXISTS fn_register_user_for_event(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS fn_trg_validate_wallet_balances() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_outbox_payment_completed() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_outbox_event_status() CASCADE;
DROP FUNCTION IF EXISTS fn_set_updated_at() CASCADE;
```

### Rollback Phase 2: Operations, Outbox & Audit Tables
```sql
DROP TABLE IF EXISTS system_configurations CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS scheduled_tasks CASCADE;
DROP TABLE IF EXISTS notification_logs CASCADE;
DROP TABLE IF EXISTS notification_templates CASCADE;
DROP TABLE IF EXISTS outbox_events CASCADE;
```

### Rollback Phase 3: Leaderboards, Results & Financial Tables
```sql
DROP TABLE IF EXISTS event_leaderboards CASCADE;
DROP TABLE IF EXISTS player_game_stats CASCADE;
DROP TABLE IF EXISTS result_disputes CASCADE;
DROP TABLE IF EXISTS result_submissions CASCADE;
DROP TABLE IF EXISTS match_results CASCADE;
DROP TABLE IF EXISTS payouts CASCADE;
DROP TABLE IF EXISTS payment_transactions CASCADE;
DROP TABLE IF EXISTS wallet_transactions CASCADE;
DROP TABLE IF EXISTS wallet_locks CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;
```

### Rollback Phase 4: Lobbies, Registrations & Tournaments Tables
```sql
DROP TABLE IF EXISTS room_allocations CASCADE;
DROP TABLE IF EXISTS match_rooms CASCADE;
DROP TABLE IF EXISTS event_registrations CASCADE;
DROP TABLE IF EXISTS team_members CASCADE;
DROP TABLE IF EXISTS teams CASCADE;
DROP TABLE IF EXISTS event_prize_structures CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS game_modes CASCADE;
DROP TABLE IF EXISTS games CASCADE;
```

### Rollback Phase 5: Identity & Authentication Tables
```sql
DROP TABLE IF EXISTS kyc_verifications CASCADE;
DROP TABLE IF EXISTS user_game_identities CASCADE;
DROP TABLE IF EXISTS role_permissions CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS permissions CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS user_auth CASCADE;
DROP TABLE IF EXISTS users CASCADE;
```

### Rollback Phase 6: Enums & Extensions
```sql
DROP TYPE IF EXISTS notification_status_enum CASCADE;
DROP TYPE IF EXISTS notification_channel_enum CASCADE;
DROP TYPE IF EXISTS outbox_status_enum CASCADE;
DROP TYPE IF EXISTS dispute_status_enum CASCADE;
DROP TYPE IF EXISTS result_status_enum CASCADE;
DROP TYPE IF EXISTS ledger_account_type_enum CASCADE;
DROP TYPE IF EXISTS transaction_type_enum CASCADE;
DROP TYPE IF EXISTS payment_status_enum CASCADE;
DROP TYPE IF EXISTS payment_type_enum CASCADE;
DROP TYPE IF EXISTS payment_gateway_enum CASCADE;
DROP TYPE IF EXISTS room_status_enum CASCADE;
DROP TYPE IF EXISTS registration_status_enum CASCADE;
DROP TYPE IF EXISTS event_format_enum CASCADE;
DROP TYPE IF EXISTS event_status_enum CASCADE;
DROP TYPE IF EXISTS game_platform_enum CASCADE;
DROP TYPE IF EXISTS kyc_status_enum CASCADE;
DROP TYPE IF EXISTS auth_provider_enum CASCADE;
DROP TYPE IF EXISTS user_role_enum CASCADE;

DROP EXTENSION IF EXISTS pgcrypto CASCADE;
```
