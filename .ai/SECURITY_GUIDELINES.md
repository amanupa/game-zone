# Game Zone Backend - Security & Authorization Strategy

## 1. Dual JWT Authentication Architecture
Authentication relies on a secure asymmetric or symmetric JWT dual-token scheme:

### Access Token
- **Lifetime**: Short-lived (15 minutes).
- **Transmission**: Sent via HTTP Header `Authorization: Bearer <access_token>`.
- **Payload Claims**: Must include `sub` (userId), `role`, `jti` (unique token ID), `iat`, `exp`. **NO sensitive PII or passwords**.

### Refresh Token
- **Lifetime**: Long-lived (7 days).
- **Transmission**: Sent via HTTP-Only, Secure, SameSite=Strict cookie.
- **Revocation**: Stored hashed in PostgreSQL / Redis session store. Supports immediate single-device or global logout.

---

## 2. Role-Based Access Control (RBAC)
Routes are protected by explicit authorization middleware:

```typescript
// Roles Hierarchy: GUEST < PLAYER < ORGANIZER < MODERATOR < ADMIN < SYSTEM
router.post(
  "/events",
  authMiddleware,
  authorizeRoles(["ORGANIZER", "ADMIN"]),
  createEventController
);
```

### Fine-Grained Ownership Checks
Even if a user has the `PLAYER` role, they can only view or modify resources they own (e.g. `req.user.id === wallet.userId`).

---

## 3. Defense Against OWASP Top 10 Vulnerabilities

### 1. SQL Injection (SQLi)
- **Mandate**: 100% Parameterized queries. NEVER use string formatting or template literals (`${var}`) inside SQL queries.

### 2. Password Cryptography
- Passwords must be hashed using **Argon2id** (memoryCost: 65536, timeCost: 3, parallelism: 4) or **bcrypt** (salt rounds >= 12).

### 3. Distributed Rate Limiting (Redis Token Bucket)
- **Public Auth Endpoints** (`/auth/login`, `/auth/register`): Max 5 requests / min per IP.
- **Standard API Endpoints**: Max 100 requests / min per User ID.
- **Real-Time Gaming Endpoints**: Max 300 requests / min per User ID.

### 4. Input Sanitization & Payload Validation
- Every incoming HTTP request body, query parameter, and path variable MUST be validated against a strict Zod / Joi schema prior to controller execution.
