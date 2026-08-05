# Game Zone Backend - 10 Million Users Scalability Plan

## Capacity & Load Planning

| Metric | Baseline Target | High-Load Peak Target |
| :--- | :--- | :--- |
| **Total Registered Users** | 10,000,000 | 10,000,000 |
| **Concurrent Active Users (CCU)** | 50,000 | 500,000 |
| **Requests Per Second (RPS)** | 2,000 RPS | 10,000+ RPS |
| **Database Connections** | 100 Pooled | 500 Pooled (PgBouncer) |
| **Kafka Throughput** | 5,000 msgs/sec | 25,000 msgs/sec |

---

## Infrastructure Scaling Roadmap
1. **Stateless API Pods**: Kubernetes Horizontal Pod Autoscaler (HPA) triggers scaling from 5 to 50 pods when CPU exceeds 60%.
2. **PostgreSQL Read Replicas**: Write queries routed to Primary; read queries distributed across 3+ Read Replicas.
3. **Redis Cluster Partitioning**: Redis sharding for sorted sets (Leaderboards) and session caching.
4. **Kafka Partitioning**: All topics configured with minimum 6 to 12 partitions to parallelize consumer group processing.
