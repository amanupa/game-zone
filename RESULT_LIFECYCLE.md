# Game Zone Backend - Match Result & Dispute Lifecycle

## Result Verification Workflow

```
[ Match Finished ] ---> [ Player / API Submits Result ] ---> [ Status: SUBMITTED ]
                                                                     |
                                                       [ Cross-Validate Submissions ]
                                                                     |
                                            +------------------------+------------------------+
                                            | (Scores Match)                                  | (Scores Conflict)
                                            v                                                 v
                                  [ Status: VERIFIED ]                              [ Status: DISPUTED ]
                                            |                                                 |
                                            v                                                 v
                                 [ Trigger Prize Payout ]                           [ Admin Manual Audit ]
```

---

## Dispute Resolution Rules
- If both player submissions match, result is automatically marked `VERIFIED`.
- If submissions conflict or a screenshot dispute is raised, match status moves to `DISPUTED`.
- An Admin / Moderator audits proof via the Admin Dashboard and manually confirms final scores.
