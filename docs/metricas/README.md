# Métricas — referência para novos projetos

Pacote padrão das APIs NestJS da família (implementado em **erpclass-kb** e **erpclass-bot**). Copie `src/metrics/` + o `AppInterceptor` desses repos.

Guia para o agente: skill `nestjs-clean-architecture` → [metricas.md](../../skills/nestjs-clean-architecture/metricas.md).

## Stack

| Camada | Tecnologia | Endpoint / destino |
|---|---|---|
| Métricas | Prometheus (`@willsoto/nestjs-prometheus`, `prom-client`) | `GET /metrics` |
| Saúde | JSON próprio | `GET /health` |
| Traces | OpenTelemetry SDK (OTLP HTTP) | `metrics.tracing.otlpUrl` |
| Profiling | Pyroscope Node | `metrics.pyroscope.serverAddress` |
| Logs | Winston → stdout JSON (prod) / console+file (dev) | Loki em `logs.erpclass.com.br` |
| Correlação | `requestId` (UUID) no interceptor | ACCESS / ERROR |

Infra: vm04 (`targets.erpclass.com.br` Prometheus, `logs.erpclass.com.br` Grafana/Loki). Ver `erpclass-bot/docs/infrastructure.md`.

## Métricas de aplicação (RED)

Além das default do Node:

- `http_requests_total` — volume
- `http_request_duration_seconds` — latência (buckets 5ms–10s)
- `http_requests_in_flight` — concorrência
- `errors_total` — erros por `error_type`

Label `app` = slug do serviço (`kb`, `bot`, …).

## Health

```json
{
  "status": "ok",
  "timestamp": "2026-08-28T02:00:00.000Z",
  "service": "erpclass-kb",
  "environment": "production"
}
```

Bot acrescenta `"redis": "ok" | "degraded"`.

Não documentar health/metrics no Swagger (`@ApiExcludeController`).

## Produção vs desenvolvimento

| | Dev | Prod |
|---|---|---|
| Prometheus / health | sim | sim |
| Tracing OTLP | não sobe (`main.ts` só inicia se não-dev **e** URL preenchida) | sim |
| Pyroscope | não | sim |
| Formato de log | texto colorido + `file.log` | JSON flattening p/ Loki |

## O que não fazer

- Logar query string com token.
- Usar URL completa como label Prometheus (explode cardinalidade).
- Exigir JWT em `/metrics` — o scraper da vm04 não autentica como usuário.
- Esquecer bypass do `ApiKeyGuard` em `/metrics` (o KB já trata o path).
