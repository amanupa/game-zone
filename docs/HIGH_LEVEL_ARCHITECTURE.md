# Game Zone Backend - High-Level Architecture

## Overall End-to-End System Architecture

```
                                  [ Web Client / Mobile App / Console ]
                                                   |
                                                   v
                                     [ Cloudflare / Load Balancer ]
                                                   |
                                                   v
                                     [ Express API Gateway Nodes ]
                                       (Rate Limit & JWT Auth)
                                                   |
          +----------------------------------------+----------------------------------------+
          |                                        |                                        |
          v                                        v                                        v
  [ Auth & Users Service ]               [ Tournament & Rooms ]                  [ Wallet & Payments ]
          |                                        |                                        |
          +----------------------------------------+----------------------------------------+
                                                   |
                                                   v
                               [ Transactional Outbox Pattern ]
                                                   |
                                                   v
                                       [ Apache Kafka Cluster ]
                                  (Event Streaming & Decoupling)
                                                   |
          +----------------------------------------+----------------------------------------+
          |                                        |                                        |
          v                                        v                                        v
  [ Redis Cluster ]                    [ PostgreSQL Primary ]                   [ Push Notification Worker ]
(Leaderboards & Caching)                (ACID Data Store)                        (FCM / Email / WebSockets)
                                                   |
                                                   v
                                      [ PostgreSQL Read Replicas ]
                                       (High-Throughput Reads)
```

---

## Architectural Guarantees
1. **Stateless Express Tier**: API Gateway instances hold no local memory state. Scale horizontally seamlessly behind load balancers.
2. **Transactional Outbox Pattern**: Database state mutations and Kafka domain events are written atomically to PostgreSQL in a single transaction, guaranteeing 100% data consistency.
3. **Storage Segregation**: High-volume, transient score updates reside in **Redis Cluster** sorted sets; permanent financial and transaction audit logs reside in **PostgreSQL**.
