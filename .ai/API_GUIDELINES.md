# Game Zone Backend - REST API & Kafka Event Specifications

## 1. RESTful HTTP API Conventions

### Base Endpoint URL Format
`https://api.gamezone.com/v1/{module}/{resource}`

### HTTP Method Mapping
- `GET`: Retrieve entity or list. Pure & idempotent.
- `POST`: Create entity or execute business action.
- `PUT`: Complete replacement of entity.
- `PATCH`: Partial update of entity fields.
- `DELETE`: Remove or soft-delete entity.

### Standard Response Envelopes

#### Success Response Envelope (HTTP 200 / 201)
```json
{
  "success": true,
  "data": {
    "userId": "usr_7b9d4e12-8c43-4f21-9988-123456789abc",
    "username": "shadow_gamer",
    "email": "shadow@gamezone.com"
  },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  },
  "timestamp": "2026-07-28T19:12:00.000Z"
}
```

#### Error Response Envelope (HTTP 4xx / 5xx)
```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_FUNDS",
    "message": "Wallet balance is insufficient to perform this transaction.",
    "details": [
      {
        "field": "amount",
        "issue": "Required 5000 credits, available balance is 1200 credits."
      }
    ],
    "traceId": "req-9842a-431b-8890"
  },
  "timestamp": "2026-07-28T19:12:00.000Z"
}
```

---

## 2. Kafka Event Specifications

### Topic Naming Structure
`gamezone.{module_name}.{entity_name}.{event_type}`
- Example: `gamezone.auth.user.registered`
- Example: `gamezone.wallet.balance.credited`
- Example: `gamezone.events.tournament.started`

### Standard Kafka Event Message Envelope
All Kafka events produced across services MUST adhere to this exact JSON schema:

```json
{
  "eventId": "evt_e3b0c442-98fc-42c1-a877-3e110c716104",
  "eventType": "USER_REGISTERED",
  "eventVersion": "1.0",
  "aggregateId": "usr_7b9d4e12-8c43-4f21-9988-123456789abc",
  "timestamp": "2026-07-28T19:12:00.000Z",
  "producer": "auth-service",
  "payload": {
    "userId": "usr_7b9d4e12-8c43-4f21-9988-123456789abc",
    "email": "shadow@gamezone.com",
    "registeredAt": "2026-07-28T19:12:00.000Z"
  },
  "metadata": {
    "correlationId": "corr_9988221100",
    "userIp": "192.168.1.1"
  }
}
```

### Idempotency Consumer Requirement
Every Kafka Consumer MUST track processed `eventId` strings in Redis or PostgreSQL (`processed_events` table) with a 7-day TTL to guarantee idempotency under network retries.
