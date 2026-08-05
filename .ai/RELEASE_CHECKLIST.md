# Game Zone Backend - Production Release Readiness Checklist

Execute this checklist before deploying any release to staging or production environments.

---

## 1. Build & Container Security
- [ ] Multi-stage Dockerfile builds successfully with non-root user (`USER node`).
- [ ] Container image scanned with 0 Critical / High vulnerabilities.
- [ ] No secrets or API keys hardcoded in code or Docker image.

## 2. Database Migration Integrity
- [ ] Migration scripts executed and verified forward and backward (rollback tested).
- [ ] Indexes created concurrently (`CREATE INDEX CONCURRENTLY`) to prevent locking.
- [ ] Backup snapshot completed before migration.

## 3. Kafka & Messaging Infrastructure
- [ ] Kafka topics created with minimum 6 partitions for high concurrency.
- [ ] Dead-Letter Queues (DLQ) configured for failed event processing.
- [ ] Consumer group lag alarms established.

## 4. Health & Observability
- [ ] `/health/liveness` returns 200 OK.
- [ ] `/health/readiness` validates PostgreSQL, Redis, and Kafka connectivity.
- [ ] Prometheus metrics endpoint (`/metrics`) active.
- [ ] Structured JSON logs emitted with trace IDs.

## 5. Post-Deployment Traffic Routing
- [ ] Canary traffic routing verified (10% -> 50% -> 100%).
- [ ] Error rates and p99 latency monitored post-deploy.
