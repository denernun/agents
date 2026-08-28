---
name: metricas-nestjs
description: Métricas, tracing, health e logs estruturados das APIs NestJS ERPCLASS (Prometheus, OpenTelemetry, Pyroscope, Loki). Use ao criar API nova, endpoint de produção ou revisar observabilidade.
---

# Métricas — padrão ERPCLASS

Fonte canônica humana: [`docs/metricas/README.md`](../../../docs/metricas/README.md) no hub `D:\AGENTS`.

Kb e bot já implementam o pacote. **API nova copia `src/metrics/`** desses dois, não inventa stack.

## O que já existe (kb + bot)

| Sinal | Onde | Quando |
|---|---|---|
| Prometheus `/metrics` | `@willsoto/nestjs-prometheus` | sempre |
| RED HTTP | `MetricsService` + `AppInterceptor` | sempre |
| Health `GET /health` | `MetricsController` | sempre (fora do Swagger) |
| Logs ACCESS/ERROR JSON | Winston + `AppInterceptor` (`requestId`) | sempre; prod = JSON p/ Loki |
| OpenTelemetry traces | `metrics.tracing.ts` (HTTP, Nest, pg) | **só produção** se `metrics.tracing.otlpUrl` |
| Pyroscope | `metrics.pyroscope.ts` | **só produção** se `serverAddress` + `appName` |
| Redis no health | só bot | `redis: ok \| degraded` |

Labels Prometheus: `app: 'kb'` ou `app: 'bot'`.

## Séries obrigatórias

| Métrica | Tipo | Labels |
|---|---|---|
| `http_requests_total` | Counter | method, route, status_code |
| `http_request_duration_seconds` | Histogram | method, route, status_code |
| `http_requests_in_flight` | Gauge | method, route |
| `errors_total` | Counter | method, route, error_type |
| default Node (`process_*`, …) | defaultMetrics | — |

Rota no interceptor: padrão Nest (`/api/v1/kb/search`), **não** URL com IDs (cardinalidade).

## Config (`metrics` no JSON)

```json
"metrics": {
  "pyroscope": { "serverAddress": "", "appName": "erpclass-kb", "authToken": "" },
  "tracing": { "otlpUrl": "", "serviceName": "erpclass-kb", "serviceVersion": "1.0.0" }
}
```

Vazio = no-op. Prod: OTLP em `targets`/`tempo` da vm04; logs em `logs.erpclass.com.br` (Loki/Grafana).

## Checklist em API nova

- [ ] `MetricsModule` no `AppModule` + `PrometheusModule.register({ path: '/metrics' })`
- [ ] `AppInterceptor` chama `startTimer` / `recordError`
- [ ] `GET /health` com `status`, `timestamp`, `service`, `environment`
- [ ] Health e metrics **públicos** (bypass de API key) e `@SkipThrottle`
- [ ] `@ApiExcludeController` no health
- [ ] Winston JSON em produção (flatten de `message` para Loki)
- [ ] `requestId` em todo ACCESS/ERROR
- [ ] `startTracing` / `startPyroscope` **antes** do `NestFactory.create`, só se `NODE_ENV !== development`
- [ ] Body sanitizado (password, token, apiKey) nos logs de debug

Não exponha `/metrics` na internet sem a rede de observabilidade (vm04). Health pode ser público para load balancer.
