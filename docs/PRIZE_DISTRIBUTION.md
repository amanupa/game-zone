# Game Zone Backend - Automated Prize Distribution Engine

## Prize Allocation & Settlement Flow
Once a match result moves to `VERIFIED`, the Prize Distribution Engine executes automated payouts.

```
[ Verified Match Result ] ---> [ Retrieve Event Prize Structure ]
                                            |
                                            v
                               [ Calculate Rank Breakdown ]
                                            |
                      +---------------------+---------------------+
                      | (1st Place: 50%)    | (2nd Place: 30%)    | (3rd Place: 20%)
                      v                     v                     v
                [ Winner 1 ]           [ Winner 2 ]          [ Winner 3 ]
                      |                     |                     |
                      +---------------------+---------------------+
                                            |
                                            v
                              [ Execute Wallet Ledger Credit ]
                                            |
                                            v
                              [ Emit PrizeDistributed Event ]
```

---

## Guarantees
- **Atomicity**: All payouts for a tournament execute within a single PostgreSQL ACID transaction.
- **Idempotency**: Payout processing checks `payout_status` flag to guarantee zero double-disbursements.
