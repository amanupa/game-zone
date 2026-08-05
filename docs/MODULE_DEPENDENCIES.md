# Game Zone Backend - Module Dependency Matrix

## Architectural Coupling Strategy
To maintain Clean Architecture and high system scalability, dependencies between modules are governed by two distinct communication patterns:
1. **Direct Synchronous Calls (In-Process Application Layer)**: Only allowed for foundational domain references (e.g. `registrations` calling `wallet` interface for balance check).
2. **Asynchronous Event-Driven Decoupling (Kafka Event Bus)**: Mandatory for cross-domain notifications, room generation triggers, and score calculations.

---

## Cross-Module Dependency Matrix

| Module | Direct Dependencies (Sync Interfaces) | Event Subscriptions (Kafka Topics) |
| :--- | :--- | :--- |
| **`auth`** | None | None |
| **`users`** | `auth` | `gamezone.auth.user.registered` |
| **`games`** | None | None |
| **`wallet`** | `users` | `gamezone.payments.deposit.completed` |
| **`payments`** | `wallet`, `users` | None |
| **`events`** | `games`, `users` | None |
| **`registrations`** | `events`, `users`, `wallet` | None |
| **`rooms`** | `events`, `games` | `gamezone.registrations.slot.confirmed` |
| **`results`** | `rooms`, `events`, `users` | `gamezone.rooms.match.completed` |
| **`leaderboard`** | `games`, `events` | `gamezone.results.score.verified` |
| **`notifications`**| `users` | `gamezone.*.*` (All Domain Events) |
| **`scheduler`** | `events`, `rooms` | None (Triggers cron event emissions) |
| **`admin`** | All Modules (Read-only / Audit) | `gamezone.*.*` |
| **`monitoring`** | Infrastructure runtime | None |
| **`deployment`** | System runtime | None |

---

## Dependency Graph (Topological Flow)

```
[ auth ] -------------> [ users ]
                           |
                           v
[ games ] ------------> [ wallet ] <------------ [ payments ]
   |                       |
   v                       v
[ events ] -----------> [ registrations ]
   |                       |
   v                       v
[ scheduler ] --------> [ rooms ]
                           |
                           v
                       [ results ]
                           |
                           v
                       [ leaderboard ] ----> [ notifications ]
```
