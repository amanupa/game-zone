# Game Zone Backend - Player Tournament Registration Lifecycle

## Registration Flow & Concurrency Defense
High-profile tournaments experience high flash traffic (e.g. 1,000 slots filled in 2 seconds). The registration lifecycle prevents overselling using **PostgreSQL Row-Level Locking** or **Redis Distributed Locks**.

```
[ User Submit Registration ] ---> [ Verify Eligibility & KYC ]
                                            |
                                            v
                              [ Lock Entry Fee in Wallet ]
                                            |
                                            v
                              [ Reserve Slot (Pessimistic Lock) ]
                                            |
                         +------------------+------------------+
                         | (Slot Available)                    | (Slot Full)
                         v                                     v
             [ Confirm Registration ]              [ Rollback Wallet Lock ]
                         |                                     |
                         v                                     v
          [ Emit SlotConfirmed Event ]             [ Return 409 Conflict ]
```

---

## Concurrency Protection Algorithm
```sql
-- Atomically reserve slot and prevent race conditions
UPDATE events 
SET filled_slots = filled_slots + 1 
WHERE id = $event_id AND filled_slots < max_slots;
```
If `UPDATE` returns 0 affected rows, the tournament is full; the transaction immediately rolls back the wallet lock and returns an `INSUFFICIENT_SLOTS` error to the client.
