# Game Zone Entity-Relationship (ER) Diagram

The following Mermaid diagram maps out the complete relational topology across all 10 domain modules.

```mermaid
erDiagram

    users ||--o{ user_auth : "has authenticators"
    users ||--o{ user_roles : "assigned"
    roles ||--o{ user_roles : "granted to"
    roles ||--o{ role_permissions : "contains"
    permissions ||--o{ role_permissions : "belongs to"
    users ||--o{ user_game_identities : "owns game handles"
    users ||--o{ kyc_verifications : "submits KYC"
    users ||--o1 wallets : "owns wallet"

    games ||--o{ game_modes : "defines modes"
    games ||--o{ user_game_identities : "linked to"
    games ||--o{ events : "hosts tournaments"
    game_modes ||--o{ events : "specifies format"

    events ||--o{ event_prize_structures : "defines payout tiers"
    events ||--o{ event_registrations : "receives registrations"
    events ||--o{ match_rooms : "generates match lobbies"
    events ||--o{ event_leaderboards : "ranks players"

    users ||--o{ teams : "captains"
    teams ||--o{ team_members : "includes"
    users ||--o{ team_members : "joins team"
    teams ||--o{ event_registrations : "registers squad"
    users ||--o{ event_registrations : "registers solo"

    match_rooms ||--o{ room_allocations : "allocates seats"
    users ||--o{ room_allocations : "seated in"
    teams ||--o{ room_allocations : "seated squad"

    wallets ||--o{ wallet_locks : "locks escrow"
    events ||--o{ wallet_locks : "locks entry fee"
    wallets ||--o{ wallet_transactions : "ledger entries"
    users ||--o{ payment_transactions : "initiates payment"
    wallets ||--o{ payment_transactions : "funds wallet"
    users ||--o{ payouts : "requests withdrawal"
    wallets ||--o{ payouts : "debited for payout"

    match_rooms ||--o{ match_results : "produces results"
    events ||--o{ match_results : "tracked in"
    match_results ||--o{ result_submissions : "contains submissions"
    users ||--o{ result_submissions : "submits proof"
    match_results ||--o{ result_disputes : "has disputes"
    users ||--o{ result_disputes : "raises dispute"

    users ||--o{ player_game_stats : "tracks stats"
    games ||--o{ player_game_stats : "stats per game"
    users ||--o{ event_leaderboards : "ranked player"

    users ||--o{ notification_logs : "receives notification"
    notification_templates ||--o{ notification_logs : "templated by"

    users ||--o{ audit_logs : "actor"

    users {
        uuid id PK
        string username UK
        string email UK
        string phone UK
        string password_hash
        enum kyc_status
        boolean is_active
        boolean is_banned
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }

    user_game_identities {
        uuid id PK
        uuid user_id FK
        uuid game_id FK
        string in_game_id
        string in_game_name
        string rank_tier
        boolean is_verified
    }

    games {
        uuid id PK
        string code UK
        string name
        enum platform
        boolean is_active
    }

    events {
        uuid id PK
        uuid game_id FK
        uuid game_mode_id FK
        string title
        numeric entry_fee
        numeric prize_pool
        integer max_slots
        integer filled_slots
        enum status
        timestamptz tournament_start_at
    }

    event_registrations {
        uuid id PK
        uuid event_id FK
        uuid user_id FK
        uuid team_id FK
        enum registration_status
        integer slot_number
        timestamptz registered_at
    }

    match_rooms {
        uuid id PK
        uuid event_id FK
        string room_name
        string room_id_code
        string room_password
        enum status
        timestamptz scheduled_time
    }

    wallets {
        uuid id PK
        uuid user_id FK_UK
        numeric available_balance
        numeric locked_balance
        numeric total_deposited
        numeric total_won
        boolean is_frozen
    }

    wallet_transactions {
        uuid id PK
        uuid wallet_id FK
        uuid reference_id
        enum transaction_type
        enum account_type
        numeric amount
        numeric balance_after
        timestamptz created_at
    }

    payment_transactions {
        uuid id PK
        uuid user_id FK
        uuid wallet_id FK
        enum gateway
        enum payment_type
        string gateway_order_id
        numeric amount
        enum status
    }

    match_results {
        uuid id PK
        uuid event_id FK
        uuid room_id FK
        enum status
        uuid verified_by FK
    }

    result_submissions {
        uuid id PK
        uuid match_result_id FK
        uuid submitted_by FK
        integer rank_achieved
        integer kills_count
        numeric score_points
        string proof_screenshot_url
    }

    outbox_events {
        uuid id PK
        string aggregate_type
        uuid aggregate_id
        string event_type
        jsonb payload_json
        enum status
        timestamptz created_at
    }

    audit_logs {
        uuid id PK
        uuid actor_id FK
        string ip_address
        string action
        string resource_type
        uuid resource_id
        timestamptz created_at
    }
```
