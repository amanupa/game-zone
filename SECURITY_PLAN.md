# Game Zone Backend - End-to-End Security Architecture

## Security Pillars & Defenses

### 1. Identity & Access Control
- Dual JWT architecture with short-lived (15m) access tokens and HTTP-Only refresh cookies.
- Password hashing using **Argon2id** (memoryCost: 65536, timeCost: 3, parallelism: 4).

### 2. Network & Application Defense
- Distributed rate limiting via Redis token bucket algorithm.
- TLS 1.3 encryption in transit for all endpoints.
- CORS restricted strictly to verified frontend domain origins.

### 3. Data Integrity & Financial Security
- 100% Parameterized SQL queries to prevent SQL Injection.
- Double-entry ledger validation for all wallet movements.
- Encrypted sensitive PII fields using AES-256-GCM.
