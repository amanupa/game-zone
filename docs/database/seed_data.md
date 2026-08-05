# Game Zone Seed Data Specification

This document details initial system seed data required to bootstrap environment setup.

---

## 1. System Games Seeding
```sql
INSERT INTO games (id, code, name, publisher, platform, is_active) VALUES
('11111111-1111-4111-8111-111111111111', 'BGMI', 'Battlegrounds Mobile India', 'Krafton', 'MOBILE', TRUE),
('22222222-2222-4222-8222-222222222222', 'FREE_FIRE', 'Free Fire MAX', 'Garena', 'MOBILE', TRUE),
('33333333-3333-4333-8333-333333333333', 'COD', 'Call of Duty: Mobile', 'Activision', 'MOBILE', TRUE);
```

## 2. Game Modes Seeding
```sql
INSERT INTO game_modes (id, game_id, name, max_players_per_team, max_teams, description) VALUES
(gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'Solo Battle Royale', 1, 100, '100 player classic solo BR'),
(gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'Squad Battle Royale', 4, 25, '25 team squad BR lobby'),
(gen_random_uuid(), '22222222-2222-4222-8222-222222222222', 'Squad Clash Squad', 4, 2, '4v4 Clash Squad arena'),
(gen_random_uuid(), '33333333-3333-4333-8333-333333333333', 'Search & Destroy 5v5', 5, 2, '5v5 tactical plant/defuse');
```

## 3. RBAC Roles Seeding
```sql
INSERT INTO roles (id, name, description) VALUES
('a1111111-1111-4111-8111-111111111111', 'SUPER_ADMIN', 'Unrestricted administrative access'),
('b2222222-2222-4222-8222-222222222222', 'ADMIN', 'Platform operational admin'),
('c3333333-3333-4333-8333-333333333333', 'MODERATOR', 'Dispute arbiter and room creator'),
('d4444444-4444-4444-8444-444444444444', 'ORGANIZER', 'Third-party tournament organizer'),
('e5555555-5555-4555-8555-555555555555', 'PLAYER', 'Standard registered player');
```

## 4. Notification Templates Seeding
```sql
INSERT INTO notification_templates (id, code, channel, subject_template, body_template, is_active) VALUES
(gen_random_uuid(), 'ROOM_CREDS_DISTRIBUTED', 'PUSH', NULL, 'Your match room for {{tournament_title}} is ready! Room ID: {{room_id}}, Pass: {{room_password}}', TRUE),
(gen_random_uuid(), 'PRIZE_CREDITED', 'IN_APP', NULL, 'Congratulations! Your wallet was credited with {{amount}} {{currency}} for winning Rank #{{rank}} in {{tournament_title}}.', TRUE),
(gen_random_uuid(), 'WITHDRAWAL_PROCESSED', 'SMS', NULL, 'GameZone: Your withdrawal of {{net_amount}} INR has been transferred. UTR: {{reference_number}}.', TRUE);
```

## 5. System Configurations Seeding
```sql
INSERT INTO system_configurations (id, config_key, config_value, description) VALUES
(gen_random_uuid(), 'PLATFORM_ENTRY_COMMISSION_PCT', '{"value": 10.0}', 'Platform percentage fee charged on tournament entry pools'),
(gen_random_uuid(), 'WITHDRAWAL_MIN_AMOUNT', '{"value": 100.0}', 'Minimum user withdrawal request threshold'),
(gen_random_uuid(), 'TDS_TAX_PERCENTAGE', '{"value": 30.0}', 'Indian government Tax Deducted at Source percentage on winnings');
```
