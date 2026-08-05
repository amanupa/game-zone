# Game Zone Backend - Clean Architecture & System Blueprint

## System Layer Blueprint

```
+-----------------------------------------------------------------------------------+
|                              PRESENTATION LAYER                                   |
|   Express Controllers  |  HTTP Routers  |  Middlewares  |  Input Validators       |
+----------------------------------------v------------------------------------------+
                                         | Invocations
+----------------------------------------v------------------------------------------+
|                              APPLICATION LAYER                                    |
|   Use Cases  |  Command/Query Handlers  |  Application DTOs  | Service Interfaces |
+----------------------------------------v------------------------------------------+
                                         | References Domain
+----------------------------------------v------------------------------------------+
|                                 DOMAIN LAYER                                      |
|   Entities  |  Value Objects  |  Domain Events  |  Repository Interfaces (Abstractions) |
+----------------------------------------^------------------------------------------+
                                         | Implements Interfaces
+----------------------------------------^------------------------------------------+
|                             INFRASTRUCTURE LAYER                                  |
|   PostgreSQL Repositories  |  Kafka Producers/Consumers  |  Redis Cache  |  JWT   |
+-----------------------------------------------------------------------------------+
```

---

## 1. Domain Layer (`src/domain/`) Rules
The Domain Layer represents the core business domain of Game Zone. It is completely framework-agnostic.

### Rules:
1. **Zero External Dependencies**: Must NOT import Express, PostgreSQL (`pg`), Kafka (`kafkajs`), Redis (`ioredis`), or ORMs.
2. **Entities**: Domain entities (e.g., `User`, `Wallet`, `GameRoom`) encapsulate business state and invariants.
3. **Value Objects**: Immutable attributes containing structural validation (e.g., `Email`, `Money`, `MatchScore`).
4. **Repository Interfaces**: Define abstract persistence contracts (e.g., `IUserRepository`, `IWalletRepository`).
5. **Domain Events**: Pure TypeScript event payloads emitted when significant domain state changes occur (e.g., `UserRegisteredDomainEvent`, `MatchCompletedDomainEvent`).

---

## 2. Application Layer (`src/application/`) Rules
The Application Layer orchestrates domain entities to perform application-specific use cases.

### Rules:
1. **Use Cases**: Each use case represents a single atomic business action (e.g., `RegisterUserUseCase`, `JoinGameRoomUseCase`).
2. **DTOs**: Data Transfer Objects used to accept input data from controllers and return formatted results.
3. **Interfaces**: Defines abstractions for infrastructure services (e.g., `INotificationService`, `IPaymentGatewayService`).
4. **No Direct HTTP/DB Details**: Does not parse HTTP headers or construct SQL statements.

---

## 3. Infrastructure Layer (`src/infrastructure/`) Rules
The Infrastructure Layer handles external communications, databases, caches, and third-party integrations.

### Rules:
1. **Repository Implementations**: Implements domain interfaces using PostgreSQL client (`pg`) or Query Builder (Knex) (e.g., `PgUserRepository implements IUserRepository`).
2. **Kafka Event Bus**: Implements Kafka Event Producers (`KafkaEventPublisher`) and Event Consumers.
3. **Redis Caching**: Implements distributed caching adapters (`RedisCacheService`).
4. **Security Adapters**: Concrete JWT token generators (`JwtTokenAdapter`) and password hashing services (`Argon2PasswordHasher`).

---

## 4. Presentation Layer (`src/presentation/`) Rules
The Presentation Layer handles HTTP communication with client applications.

### Rules:
1. **Express Controllers**: Accepts Express `Request`, validates input DTOs, invokes Application Use Cases, and formats Express `Response`.
2. **Middlewares**: `authMiddleware` (JWT verification), `rateLimitMiddleware` (Redis rate limiting), `errorHandler` (Centralized error mapping).
3. **Routing**: Express `Router` definitions binding HTTP routes to controllers.

---

## 5. Dependency Injection (DI) & Transactional Outbox Pattern

### Dependency Injection Rules
- All Use Cases, Repositories, Services, and Controllers must be wired using Constructor Injection or an IoC Container (`Awilix` / `TSyringe`).
- Controllers receive Use Cases; Use Cases receive Repository Interfaces and Service Interfaces.

### Transactional Outbox Pattern (PostgreSQL + Kafka)
To guarantee consistency between PostgreSQL operations and Kafka events:
1. When a domain event occurs during a Use Case execution, write both the database state change and the event into an `outbox` table in PostgreSQL within the **SAME local database transaction**.
2. A background Outbox Processor worker reads unconsumed events from `outbox` and publishes them to Apache Kafka reliably.
3. Guarantees **At-Least-Once Delivery** across distributed services without two-phase commits.
