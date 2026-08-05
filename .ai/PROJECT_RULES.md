# Game Zone Backend - Core Project Rules & AI Governance

## System Context & Architectural Vision
Game Zone Backend is a high-throughput, enterprise-grade online gaming platform backend designed to serve **10 Million Active Users** with a peak capacity of **500,000 Concurrent Active Users (CCU)** and **10,000+ Requests Per Second (RPS)**.

This repository is strictly governed by an **AI-Agnostic Software Development Lifecycle (AI-SDLC)**. All AI Agents (Gemini, Claude, GPT, DeepSeek, Qwen, or any future LLM engine) operating within this codebase MUST treat this document and all guidelines inside `.ai/` as non-negotiable architectural laws.

---

## 1. Core Directives & Mandates for AI Agents

### Rule 1.1: Single Source of Truth (`.ai/`)
- Every AI agent MUST inspect and follow the guidelines defined inside `.ai/` before initiating planning, design, or implementation tasks.
- No AI agent has the authorization to alter tech stack choices, architectural patterns, directory structures, or security constraints without explicitly updating the governing document first.

### Rule 1.2: Mandatory Clean Architecture & Layer Isolation
Code must be segregated into four strict concentric layers:
1. **Domain Layer (`src/domain/`)**: Entities, Value Objects, Domain Events, and Repository Interfaces. **ZERO EXTERNAL DEPENDENCIES** (No Express, PostgreSQL, Kafka, Redis, or ORM frameworks allowed).
2. **Application Layer (`src/application/`)**: Use Cases, Input/Output DTOs, Application Services, and Event Handlers. Pure orchestration of domain logic.
3. **Infrastructure Layer (`src/infrastructure/`)**: Concrete implementations of Repository interfaces (PostgreSQL), Event Publishers/Consumers (Kafka), Cache Adapters (Redis), Encryption, and JWT services.
4. **Presentation Layer (`src/presentation/`)**: Express Controllers, HTTP Routers, Request Validators, and Middlewares.

### Rule 1.3: Non-Negotiable Tech Stack
- **Language & Runtime**: Node.js (LTS) + TypeScript (Strict Mode enabled).
- **HTTP Web Framework**: Express.js.
- **Relational DBMS**: PostgreSQL 15+ (ACID compliant, relational storage, partition support).
- **Event Streaming & Async Messaging**: Apache Kafka.
- **Containerization & Deployment**: Docker (Multi-stage builds) & Kubernetes-ready.
- **Authentication & Security**: Dual JWT token architecture (Access + Refresh tokens), Argon2id / bcrypt password hashing.
- **Design Patterns**: Repository Pattern, Dependency Injection (IoC Container), Factory Pattern.

### Rule 1.4: Strict SOLID Principles Compliance
- **SRP (Single Responsibility)**: A class/function must have one, and only one, reason to change.
- **OCP (Open/Closed)**: Software entities must be open for extension, but closed for modification.
- **LSP (Liskov Substitution)**: Subtypes must be completely substitutable for their base types.
- **ISP (Interface Segregation)**: Clients must not be forced to depend on methods they do not use.
- **DIP (Dependency Inversion)**: High-level modules must depend on abstractions (interfaces), never on concrete details.

### Rule 1.5: 12-Stage Module SDLC Lifecycle
Before any backend TypeScript code is authored for a module in `modules/<module_name>/`, the AI Agent MUST complete stages 1 through 4 in the module's documentation:
- Stage 1: `requirements.md`
- Stage 2: `architecture.md`
- Stage 3: `database.md`
- Stage 4: `api_contract.md`
- Stage 5: `development.md`
- Stage 6: `sync.md`
- Stage 7: `testing.md`
- Stage 8: `performance.md`
- Stage 9: `security.md`
- Stage 10: `review.md`
- Stage 11: `diff.md`
- Stage 12: `final.md`

---

## 2. Operational Rules for AI Agents

1. **No Unchecked Code Generation**: Do not jump into writing code files without fulfilling the prior documentation stage gates.
2. **Design for 10 Million Users**: Every query, event message, and data structure must be designed assuming high concurrency, distributed deployment, and horizontal scalability.
3. **No Direct Instantiation**: Never use `new PgUserRepository()` inside Express controllers or Use Cases. Dependency Injection via IoC containers or constructors is mandatory.
4. **Idempotency in Event Processing**: All Kafka event consumers must handle message redelivery safely using idempotency keys and deduplication stores.
5. **Zero Exposure of Internal Errors**: Stack traces, SQL queries, and database driver errors MUST NEVER be returned to HTTP API consumers.

---

## 3. Enforcement & Rejection Criteria
Any pull request or code change that:
- Violates Clean Architecture by importing infrastructure dependencies into domain files,
- Executes unindexed raw SQL queries or introduces N+1 query patterns,
- Skips module documentation lifecycle steps, or
- Hardcodes secrets or configuration settings,
**MUST BE REJECTED IMMEDIATELY.**
