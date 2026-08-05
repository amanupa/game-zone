# Game Zone Database Requirements Specification

## 1. Executive Summary & Scale Objectives
The Game Zone Platform database is engineered to serve as the single source of truth for a high-concurrency esports tournament management ecosystem. Designed to handle **10 Million Registered Users**, **500,000 Concurrent Active Users (CCU)**, and **10,000+ Requests Per Second (RPS)** during flash tournament registrations, the database provides extreme performance, ACID transactional safety, zero financial drift, and event delivery guarantees.

### Target Supported Games
- **BGMI** (Battlegrounds Mobile India)
- **Free Fire**
- **Call of Duty (COD)** (Mobile / Warzone)

---

## 2. Core Functional Requirements

### 2.1 User Management & Security
- Secure registration with Argon2id password hashing, email/phone verification, and OAuth (Google, Apple, Discord).
- Identity verification (KYC) supporting government ID hash validation for financial compliance.
- Gaming identities mapping player handles and unique numeric UIDs per supported game (BGMI UID, Free Fire UID, COD UID).
- Fine-grained Role-Based Access Control (RBAC) with dynamic roles (`PLAYER`, `ORGANIZER`, `MODERATOR`, `ADMIN`, `SUPER_ADMIN`) and system permissions.

### 2.2 Tournament & Event Lifecycle
- Support for multiple tournament formats: Solo, Duo, Squad, and Custom lobbies.
- Strict event state machine: `DRAFT` $\rightarrow$ `PUBLISHED` $\rightarrow$ `REGISTRATION_OPEN` $\rightarrow$ `REGISTRATION_CLOSED` $\rightarrow$ `IN_PROGRESS` $\rightarrow$ `RESULT_SETTLED` $\rightarrow$ `COMPLETED` / `CANCELLED`.
- Dynamic prize structure definitions based on rank thresholds and kill bounties.

### 2.3 Registration & Flash Concurrency Defense
- Atomic slot reservation under heavy flash traffic (up to 5,000 slot claims/sec).
- Lock entry fees in user wallet escrow before confirming slot assignment.
- Automatic waitlist management and instant rollback upon slot exhaustion or payment cancellation.

### 2.4 Room & Lobby Distribution
- Secure distribution of game lobby credentials (Room ID and Room Password) to registered players.
- Seating chart / slot allocation tracking per team and individual player.

### 2.5 Financial Engine & Double-Entry Ledger
- Double-entry bookkeeping system where every monetary movement balances across accounts (`USER_WALLET`, `SYSTEM_ESCROW`, `GATEWAY_SETTLEMENT`, `PLATFORM_FEE`, `PRIZE_POOL`).
- Support for available balance vs. locked escrow balance.
- Idempotent deposit and withdrawal processing via payment gateways (Razorpay, Stripe, PayPal).
- Automatic TDS (Tax Deducted at Source) tax calculation and tracking on prize payouts.

### 2.6 Results, Verification & Anti-Cheat Disputes
- Player and room admin score submission with screenshot/video proof URLs.
- Cross-validation logic: automatically mark results `VERIFIED` when submissions match; flag as `DISPUTED` on conflicts.
- Audit trail for admin dispute resolution and penalty logging.

### 2.7 Real-Time Leaderboards & Analytics
- Aggregate historical and tournament-level player stats (Kills, Deaths, Wins, Win Rate, K/D ratio, Total Winnings).
- Support for fast SQL leaderboard aggregations alongside Redis sorted set sync.

### 2.8 Kafka Outbox & Messaging Engine
- Transactional Outbox Pattern: Save domain events into `outbox_events` within the same DB transaction as state updates, guaranteeing At-Least-Once delivery to Kafka.
- Multi-channel notification pipeline logging (In-App, Push via FCM, Email, SMS).

### 2.9 System Operations & Audit
- Cron-driven scheduler task execution tracking.
- Immutable, partitioned audit logs recording all administrative actions, IP addresses, and payload diffs.

---

## 3. Non-Functional Requirements & Design Principles

| Category | Requirement Specification |
| :--- | :--- |
| **Database Engine** | PostgreSQL 16+ Enterprise Grade |
| **Primary Keys** | Universally Unique Identifiers (UUID v4) generated via `gen_random_uuid()` |
| **Normalization** | Strictly 3rd Normal Form (3NF). Zero unnormalized redundant data. |
| **Data Integrity** | Foreign key constraints with explicit `ON DELETE` / `ON UPDATE` actions on 100% of relations. |
| **Soft Deletes** | `deleted_at TIMESTAMP WITH TIME ZONE` on core entities (`users`, `events`, `teams`, `wallets`, `game_identities`). |
| **Audit Metadata** | `created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by` on all stateful tables. |
| **Isolation Level** | `READ COMMITTED` default; `SERIALIZABLE` or pessimistic row locks (`SELECT ... FOR UPDATE`) for wallet/registration operations. |
| **Partitioning** | Declarative Range Partitioning by `created_at` (monthly) for high-volume logs and transactions. |
| **Indexes** | B-Tree on PKs/FKs; Composite indexes on multi-column filter paths; Partial indexes on un-deleted/pending rows. |
