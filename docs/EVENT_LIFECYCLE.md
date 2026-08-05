# Game Zone Backend - Tournament Event Lifecycle

## Tournament Event State Machine

```
[ DRAFT ] ---> [ PUBLISHED ] ---> [ REGISTRATION_OPEN ] ---> [ REGISTRATION_CLOSED ]
                                                                      |
[ CANCELLED ] <--- [ COMPLETED ] <--- [ RESULT_SETTLED ] <--- [ IN_PROGRESS ]
```

---

## State Transition Specifications

### 1. `DRAFT` $ightarrow$ `PUBLISHED`
- **Trigger**: Organizer or Admin publishes tournament.
- **Actions**: Validates prize pool, entry fee, schedule, and maximum slot capacity. Emits `gamezone.events.published`.

### 2. `PUBLISHED` $ightarrow$ `REGISTRATION_OPEN`
- **Trigger**: Scheduled start time reached (`scheduler` module cron).
- **Actions**: Players can submit registration requests. Entry fee locks enabled. Emits `gamezone.events.registration.opened`.

### 3. `REGISTRATION_OPEN` $ightarrow$ `REGISTRATION_CLOSED`
- **Trigger**: Slots full OR registration deadline reached.
- **Actions**: Prevents new registrations. Emits `gamezone.events.registration.closed`. Triggers `rooms` allocation worker.

### 4. `REGISTRATION_CLOSED` $ightarrow$ `IN_PROGRESS`
- **Trigger**: Game room codes assigned and match time reached.
- **Actions**: Players join game lobbies. Emits `gamezone.events.started`.

### 5. `IN_PROGRESS` $ightarrow$ `RESULT_SETTLED`
- **Trigger**: Match finished and scores submitted by players/admins.
- **Actions**: Validates scores, resolves disputes, triggers `leaderboard` and `prize_distribution`.

### 6. `RESULT_SETTLED` $ightarrow$ `COMPLETED`
- **Trigger**: Payouts credited to winner wallets.
- **Actions**: Archive match logs. Emits `gamezone.events.completed`.
