# Game Zone Backend - AI Software Development Lifecycle (AI-SDLC) Workflow

## Overview
This document defines the strict 12-stage sequential workflow that every AI Agent (Gemini, Claude, GPT, DeepSeek, Qwen, etc.) must follow when developing, modifying, or auditing any module in this repository.

---

## The 12-Stage Module SDLC Lifecycle Flow

```
[Stage 1: Requirements] -> [Stage 2: Architecture] -> [Stage 3: Database] -> [Stage 4: API Contract]
                                                                                      |
[Stage 8: Performance] <- [Stage 7: Testing]      <- [Stage 6: Sync]        <- [Stage 5: Development]
       |
[Stage 9: Security]     -> [Stage 10: Review]      -> [Stage 11: Diff]       -> [Stage 12: Final Handover]
```

---

## Detailed Stage Requirements

### Stage 1: Requirements (`modules/<module>/requirements.md`)
- Define business goals, functional specifications, user stories, non-functional targets, and domain edge cases.

### Stage 2: Architecture (`modules/<module>/architecture.md`)
- Map Domain entities, Value Objects, Use Cases, Repository interfaces, and Clean Architecture boundaries.

### Stage 3: Database (`modules/<module>/database.md`)
- Design PostgreSQL schema, table DDLs, foreign key constraints, indexes, partitioning plan, and EXPLAIN ANALYZE query verification.

### Stage 4: API Contract (`modules/<module>/api_contract.md`)
- Specify REST HTTP endpoints (request/response JSON schemas) and Kafka Event Schemas (topics, keys, envelopes).

### Stage 5: Development Plan (`modules/<module>/development.md`)
- Plan folder layout in `src/`, file creation sequence, dependency injection wiring, and controller/use case integration.

### Stage 6: Synchronization Plan (`modules/<module>/sync.md`)
- Map cross-module dependencies, Kafka event publish/subscribe relationships, and transactional boundaries.

### Stage 7: Testing Strategy (`modules/<module>/testing.md`)
- Define Unit, Integration, and E2E API test plans, test fixtures, and mock implementations.

### Stage 8: Performance & Scalability (`modules/<module>/performance.md`)
- Plan Redis caching TTLs, seek pagination queries, connection pool settings, and 10M user load criteria.

### Stage 9: Security & Compliance (`modules/<module>/security.md`)
- Audit RBAC authorization matrix, JWT validation, rate limiting, SQL injection defense, and input sanitization.

### Stage 10: Code Review Checklist (`modules/<module>/review.md`)
- Complete self-audit against `.ai/REVIEW_CHECKLIST.md`.

### Stage 11: Diff & Revision Control (`modules/<module>/diff.md`)
- Document file changes, migrations, and git commit details.

### Stage 12: Final Handover (`modules/<module>/final.md`)
- Summarize operational readiness, health check endpoints, environment variables, and mark module PRODUCTION READY.
