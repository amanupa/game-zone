# Game Zone Backend - Multi-Channel Notification Lifecycle

## Notification Pipeline Architecture

```
[ Kafka Event Bus ] ---> [ Notification Consumer Worker ]
                                     |
                                     v
                       [ Template Rendering Engine ]
                                     |
         +---------------------------+---------------------------+
         | (Push Notification)       | (Email Alert)             | (WebSocket Real-Time)
         v                           v                           v
  [ Firebase FCM ]            [ SendGrid API ]            [ Socket.io / WS Server ]
```

---

## Priority Tier Specifications

| Priority | Channel | Target Use Cases | SLA |
| :--- | :--- | :--- | :--- |
| **HIGH** | WebSockets + Push (FCM) | Match Room Code Ready, Tournament Starting Now | < 1 Second |
| **MEDIUM** | In-App + Email | Prize Payout Credited, Registration Confirmed | < 30 Seconds |
| **LOW** | Email | Weekly Leaderboard Digest, Promotional Events | < 15 Minutes |
