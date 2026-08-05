# Game Zone Backend - Financial Payment & Ledger Lifecycle

## Double-Entry Ledger Architecture
All monetary transactions in Game Zone follow strict **Double-Entry Bookkeeping** to guarantee zero financial discrepancy.

```
[ User Deposit ] ---> [ Payment Gateway Webhook ] ---> [ Ledger: Debit Gateway / Credit User Wallet ]
                                                                     |
[ Tournament Entry ] ---> [ Ledger: Debit User Wallet / Credit Escrow Account ]
                                                                     |
[ Prize Payout ]   ---> [ Ledger: Debit Escrow Account / Credit Winner Wallet ]
```

---

## Payment Lifecycle Flow

1. **Initiation**: User requests deposit via payment gateway (Stripe/Razorpay). Transaction created in `PAYMENT_PENDING` state.
2. **Webhook Verification**: Gateway returns signed webhook payload. System verifies cryptographic signature.
3. **Idempotent Settlement**: Verifies `payment_reference_id` has not been processed.
4. **Ledger Mutation**: Inside a PostgreSQL ACID transaction:
   - Updates `payments` table status to `COMPLETED`.
   - Inserts record into `wallet_transactions` ledger.
   - Increases `wallets.available_balance`.
5. **Event Emission**: Emits `gamezone.payments.deposit.completed` via Kafka.
