# Game Zone Backend - Quality Assurance & Testing Strategy

## 1. Testing Pyramid & Thresholds

```
       /       /   \     E2E API Tests (10%)
     /-----    /       \   Integration Tests (30%)
   /---------  /           \ Unit Tests (60%)
 /-------------```

### Code Coverage Targets:
- **Overall Project Coverage**: Minimum 80% line and branch coverage.
- **Domain Layer (`src/domain/`)**: 95%+ coverage.
- **Application Use Cases (`src/application/`)**: 90%+ coverage.

---

## 2. Test Layer Execution Rules

### 1. Unit Tests (`*.spec.ts`)
- **Target**: Domain Entities, Value Objects, Application Use Cases.
- **Rule**: Must run synchronously in under 5ms per test. NO real network connections, NO database connections. Use Mocks/Stubs for repository interfaces.

### 2. Integration Tests (`*.integration.spec.ts`)
- **Target**: PostgreSQL Repositories, Redis Adapters, Kafka Producers/Consumers.
- **Rule**: Run against containerized test instances (Docker / Testcontainers). Verify table queries, constraints, transaction rollbacks, and schema migrations.

### 3. End-to-End API Tests (`*.e2e.spec.ts`)
- **Target**: Express Controllers, Middlewares, Full HTTP Request/Response flow.
- **Rule**: Executed using `Supertest`. Validates HTTP status codes, headers, response JSON envelopes, and authentication handling.

---

## 3. Automated Test Execution Commands
```bash
npm run test               # Run unit tests
npm run test:integration   # Run integration tests with test DB
npm run test:e2e           # Run E2E API tests
npm run test:coverage      # Generate test coverage report
```
