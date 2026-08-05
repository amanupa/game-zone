# Game Zone Backend - AI Code Review Checklist

Every AI Agent MUST audit code changes against this checklist before marking any module task complete.

---

## 1. Clean Architecture & Layer Isolation
- [ ] Code is separated into `domain`, `application`, `infrastructure`, `presentation`.
- [ ] Domain layer has ZERO external imports (No Express, PostgreSQL, Kafka, Redis).
- [ ] Use Cases depend on Repository Interfaces, not concrete implementations.
- [ ] Controllers delegate directly to Use Cases.

## 2. SOLID Principles Compliance
- [ ] Single Responsibility: Classes and functions have one reason to change.
- [ ] Open/Closed: Extensibility via interfaces and strategy pattern.
- [ ] Liskov Substitution: Interface implementations strictly honor interface contracts.
- [ ] Interface Segregation: Small, cohesive interfaces.
- [ ] Dependency Inversion: Constructor injection used for all dependencies.

## 3. Database & SQL Performance (10M Users)
- [ ] All SQL queries use prepared parameters (No raw string concatenation).
- [ ] Primary keys use UUIDv4 / TSID.
- [ ] Foreign keys, lookup fields, and sort columns are indexed.
- [ ] Pagination uses cursor seek method (No `OFFSET`).
- [ ] Audit columns (`created_at`, `updated_at`, `deleted_at`) present.
- [ ] Financial data uses `NUMERIC` or `BIGINT` (No `FLOAT`).

## 4. Security & Authentication
- [ ] Protected endpoints use `authMiddleware` JWT verification.
- [ ] Role-Based Access Control (RBAC) enforced.
- [ ] Input requests validated using strict Zod / Joi schemas.
- [ ] Passwords hashed with Argon2id / bcrypt (salt >= 12).
- [ ] Redis rate limiting configured on routes.

## 5. Performance & Messaging
- [ ] Main Express event loop is free of CPU-blocking calls.
- [ ] Redis caching applied to high-throughput read endpoints.
- [ ] Kafka event consumers process messages idempotently.

## 6. Testing & Documentation
- [ ] Unit tests cover domain entities and use cases (>= 80% coverage).
- [ ] Integration tests verify repository SQL operations.
- [ ] Code contains proper TSDoc comments.
- [ ] Module documentation files in `modules/<module>/` updated.
