---
name: api-design
description: Use when designing or reviewing NestJS REST endpoints, pagination, response shapes, filtering, status codes, rate limits or API versioning.
metadata:
  origin: ECC (AgentHub adaptation)
---

# API design for AgentHub products

Read [reference.md](reference.md) for REST tradeoffs and examples. First inspect
neighboring controllers, DTOs, Swagger output, exception filters and consumers.
The project's `nestjs-clean-architecture` conventions and existing public
contracts take precedence over generic examples.

- Preserve the current envelope, pagination fields and naming. An API using
  `items`/`total` and camelCase must not acquire `data`/`meta`/`per_page` merely
  because the reference shows that shape.
- Preserve existing versioning, domain vocabulary and DTO validation through
  `class-validator`, serialization and Swagger decorators. Next.js/Zod, Django
  and SQL snippets in the reference illustrate concepts; they do not prescribe
  new frameworks or database tooling for NestJS/MongoDB.
- Choose status codes and error payloads consistent with HTTP semantics and the
  application's established exception handling. Verify authorization at the
  resource/tenant boundary, bounded pagination, allowed filters/sort fields,
  and absence of internal details in serialized errors.
- Select cursor or offset pagination from actual query/access patterns. Use a
  stable, unique ordering; reference row-count thresholds and rate limits are
  examples, not measured product requirements.
- For an intentional contract change, apply `contract-first`, assess consumers
  and provide migration/versioning evidence instead of silently changing shape.

Completion evidence: endpoint/DTO diff, generated OpenAPI diff where applicable,
and relevant integration checks for success, validation, authorization, empty
results and pagination. Use commands already present in the repository.

Source: [ECC api-design](https://github.com/affaan-m/ECC/tree/8321021c54d670126ce3b2969d5deb880b4b0c2a/skills/api-design), MIT; see [LICENSE](LICENSE).
