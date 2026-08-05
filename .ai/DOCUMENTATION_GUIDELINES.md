# Game Zone Backend - Documentation Standards

## 1. Code-Level TSDoc Standard
All public domain interfaces, entities, value objects, and use cases MUST contain **TSDoc** standard documentation comments:

```typescript
/**
 * Executes user registration, validating data invariants, hashing
 * the plain-text password using Argon2id, persisting the entity,
 * and dispatching a UserRegisteredDomainEvent.
 *
 * @param dto - Validated input registration details.
 * @returns The newly created User entity.
 * @throws {UserAlreadyExistsError} If email or username is already taken.
 * @throws {ValidationError} If input DTO fails validation checks.
 */
public async execute(dto: RegisterUserDTO): Promise<UserEntity> {
  // Implementation
}
```

---

## 2. Module Documentation Synchronization Rule
Whenever an AI agent modifies code inside `src/` associated with a specific module, the agent MUST update the corresponding 12 documentation files inside `modules/<module_name>/`:
- Modified SQL schema or migration? -> Update `modules/<module>/database.md`
- Changed API routes or schemas? -> Update `modules/<module>/api_contract.md`
- Refactored Clean Architecture Use Case? -> Update `modules/<module>/architecture.md`
- Added security checks? -> Update `modules/<module>/security.md`

---

## 3. Diagrams & OpenAPI Specification
- **OpenAPI Specification**: Maintained at `docs/api/openapi.yaml`.
- **Mermaid Architectural Diagrams**: Maintained at `docs/diagrams/architecture.mermaid`.
- **Mermaid Database ERD**: Maintained at `docs/diagrams/database_erd.mermaid`.
