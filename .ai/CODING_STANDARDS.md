# Game Zone Backend - Coding Standards & TypeScript Conventions

## 1. TypeScript Strictness & Compiler Settings
All code must compile under strict TypeScript settings (`tsconfig.json`):
- `"strict": true`
- `"noImplicitAny": true`
- `"strictNullChecks": true`
- `"noUnusedLocals": true`
- `"noUnusedParameters": true`
- `"noImplicitReturns": true`

---

## 2. Concrete SOLID Code Examples

### Single Responsibility Principle (SRP)
```typescript
// BAD: Controller doing validation, hashing, DB insert, and event sending
class UserController {
  async register(req: Request, res: Response) {
    if (!req.body.email) throw new Error("Email required");
    const hashed = await bcrypt.hash(req.body.password, 10);
    const user = await db.query("INSERT INTO users...", [req.body.email, hashed]);
    await kafka.send({ topic: "user-registered", message: user });
    res.json(user);
  }
}

// GOOD: Controller delegates to Use Case
class UserController {
  constructor(private readonly registerUserUseCase: RegisterUserUseCase) {}

  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = RegisterUserDTO.fromRequest(req.body);
      const result = await this.registerUserUseCase.execute(dto);
      res.status(201).json(ApiResponse.success(result));
    } catch (error) {
      next(error);
    }
  }
}
```

### Dependency Inversion Principle (DIP)
```typescript
// BAD: Use Case depends directly on PostgreSQL repository
class RegisterUserUseCase {
  private repo = new PgUserRepository(); // Tight coupling!
}

// GOOD: Use Case depends on Domain Interface
class RegisterUserUseCase {
  constructor(
    private readonly userRepository: IUserRepository, // Abstraction!
    private readonly passwordHasher: IPasswordHasher,
    private readonly eventPublisher: IEventPublisher
  ) {}
}
```

---

## 3. Standard Naming Conventions

| Code Artifact | Convention | Example |
| :--- | :--- | :--- |
| **Classes & Interfaces** | PascalCase | `UserEntity`, `IUserRepository` |
| **Interfaces (Abstractions)** | PascalCase prefixed with `I` | `IUserRepository`, `IWalletService` |
| **Methods & Variables** | camelCase | `findUserById`, `activeSessionCount` |
| **Constants & Enums** | UPPER_SNAKE_CASE | `MAX_RETRY_ATTEMPTS`, `USER_ROLE_ADMIN` |
| **Files & Directories** | camelCase or PascalCase by role | `UserEntity.ts`, `registerUser.routes.ts` |
| **Database Tables & Columns** | snake_case | `wallet_transactions`, `user_id` |
| **Kafka Topics** | lowercase dotted | `gamezone.auth.user.registered` |

---

## 4. Domain Error Hierarchy & Handling
Never throw raw generic `Error` objects. Use the standard Domain Error hierarchy:

```typescript
export abstract class DomainError extends Error {
  constructor(message: string, public readonly errorCode: string) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export class UserNotFoundError extends DomainError {
  constructor(userId: string) {
    super(`User with ID ${userId} was not found.`, "USER_NOT_FOUND");
  }
}

export class InsufficientBalanceError extends DomainError {
  constructor(current: number, required: number) {
    super(`Required ${required} credits, but wallet only has ${current}.`, "INSUFFICIENT_FUNDS");
  }
}
```

### Express Error Middleware Translation
- `DomainError` (e.g. `UserNotFoundError`) -> HTTP 400 / 404 / 422
- `UnauthorizedError` -> HTTP 401 Unauthorized
- `ForbiddenError` -> HTTP 403 Forbidden
- `ConflictError` -> HTTP 409 Conflict
- Unexpected Exceptions -> HTTP 500 Internal Server Error (Logged with correlation Trace ID, internal details hidden).
